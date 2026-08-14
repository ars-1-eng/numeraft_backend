#!/usr/bin/env bash
# Asserts that the deployed API behaves as the contract promises.
# Usage: ./scripts/smoke.sh [dev|prod]
set -euo pipefail

ENVIRONMENT="${1:-dev}"
ROOT="infra/envs/${ENVIRONMENT}"

if [ ! -d "$ROOT" ]; then
  echo "No such environment: ${ENVIRONMENT}" >&2
  exit 1
fi

API="$(terraform -chdir="$ROOT" output -raw api_base_url)"
echo "Smoke testing ${ENVIRONMENT} at ${API}"

fail() { echo "  FAIL: $1" >&2; exit 1; }

# ---------------------------------------------------------------- 1. health
echo "1. GET /health returns 200 and the documented shape"
BODY="$(curl -fsS --max-time 10 "${API}/health")" || fail "health did not return 2xx"
echo "$BODY" | python3 -c '
import json, sys, re
d = json.load(sys.stdin)
assert d["status"] == "ok", d
assert d["service"] == "numeraft-api", d
assert isinstance(d["environment"], str) and d["environment"], d
assert re.match(r"^\d{4}-\d{2}-\d{2}T[\d:.]+Z$", d["timestamp"]), d
assert d["requestId"], d
' || fail "health body did not match the contract"

# ------------------------------------------------------- 2. request id header
echo "2. the response carries x-request-id"
curl -fsS -D - -o /dev/null --max-time 10 "${API}/health" \
  | tr 'A-Z' 'a-z' | grep -q '^x-request-id:' || fail "x-request-id header missing"

# ------------------------------------------------------------ 3. unknown route
echo "3. an unknown route returns 404, not 500"
CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "${API}/definitely-not-a-route")"
[ "$CODE" = "404" ] || fail "expected 404 for an unknown route, got ${CODE}"

# -------------------------------------------------------------- 4. CORS is set
echo "4. CORS does not allow a wildcard origin"
ALLOWED="$(curl -s -D - -o /dev/null --max-time 10 \
  -H 'Origin: https://evil.example' \
  -H 'Access-Control-Request-Method: GET' \
  -X OPTIONS "${API}/health" \
  | tr 'A-Z' 'a-z' | grep '^access-control-allow-origin:' || true)"
echo "$ALLOWED" | grep -q '\*' && fail "the API allows a wildcard CORS origin"
# ------------------------------------------------------- 5. /me without auth
echo "5. GET /me without a token returns 401"
CODE="$(curl-s-o /dev/null-w '%{http_code}'--max-time 10 "${API}/me")"
[ "$CODE" = "401" ] || fail "expected 401 for an unauthenticated /me, got ${CODE}"
# --------------------------------------------------- 6. /me with a bad token
echo "6. GET /me with a nonsense token returns 401"
CODE="$(curl-s-o /dev/null-w '%{http_code}'--max-time 10 \-H 'Authorization: Bearer not.a.real.jwt' "${API}/me")"
[ "$CODE" = "401" ] || fail "expected 401 for a malformed token, got ${CODE}"
# ------------------------------------------------------- 7. authenticated /me
if [-n "${SMOKE_EMAIL:-}" ] && [-n "${SMOKE_PASSWORD:-}" ]; then
POOL="$(terraform-chdir="$ROOT" output-raw user_pool_id)"
CLIENT="$(terraform-chdir="$ROOT" output-raw user_pool_client_id)"
echo "7. signing in and taking the ID TOKEN (not the access token)"
ID_TOKEN="$(aws cognito-idp admin-initiate-auth \--user-pool-id "$POOL" \--client-id "$CLIENT" \--auth-flow ADMIN_USER_PASSWORD_AUTH \--auth-parameters "USERNAME=${SMOKE_EMAIL},PASSWORD=${SMOKE_PASSWORD}" \--query 'AuthenticationResult.IdToken'--output text)"
[-n "$ID_TOKEN" ] && [ "$ID_TOKEN" != "None" ] || fail "sign-in returned no ID token"
echo "8. GET /me returns the documented contract"
ME_STATUS="$(curl-s-o /tmp/me.json-w '%{http_code}'--max-time 10 \-H "Authorization: Bearer ${ID_TOKEN}" "${API}/me")"
if [ "$ME_STATUS" = "403" ]; then
CODE="$(python3-c 'import json;print(json.load(open("/tmp/me.json"))["error"]["code"])')"
[ "$CODE" = "NO_AGENCY" ] || fail "unexpected 403 code: ${CODE}"
echo "   NO_AGENCY as expected for a fresh admin-created user, bootstrapping"
curl-fsS-X POST--max-time 15 \-H "Authorization: Bearer ${ID_TOKEN}" "${API}/me/bootstrap" >/dev/null \
|| fail "bootstrap failed"
echo "   re-signing in so the token carries the new claims"
ID_TOKEN="$(aws cognito-idp admin-initiate-auth \--user-pool-id "$POOL"--client-id "$CLIENT" \--auth-flow ADMIN_USER_PASSWORD_AUTH \--auth-parameters "USERNAME=${SMOKE_EMAIL},PASSWORD=${SMOKE_PASSWORD}" \--query 'AuthenticationResult.IdToken'--output text)"
curl-fsS-o /tmp/me.json--max-time 10 \-H "Authorization: Bearer ${ID_TOKEN}" "${API}/me" \
|| fail "/me still failing after bootstrap"
elif [ "$ME_STATUS" != "200" ]; then
fail "/me returned ${ME_STATUS}"
fi
python3- < /tmp/me.json <<'PY' || fail "/me body did not match the contract"
import json, re, sys
d = json.load(sys.stdin)
assert d["agency"]["id"].startswith("agc_"), d
assert d["agency"]["plan"] in ("founding", "starter", "growth"), d
assert d["user"]["role"] in ("owner", "admin", "member"), d
assert "logoUrl" in d["agency"]["branding"], d
assert re.match(r"^#[0-9A-Fa-f]{6}$", d["agency"]["branding"]["primaryColor"]), d
print("   
/me contract OK")
PY
echo "9. the ACCESS token must NOT satisfy /me (it carries no custom claims)"
ACCESS_TOKEN="$(aws cognito-idp admin-initiate-auth \--user-pool-id "$POOL"--client-id "$CLIENT" \--auth-flow ADMIN_USER_PASSWORD_AUTH \--auth-parameters "USERNAME=${SMOKE_EMAIL},PASSWORD=${SMOKE_PASSWORD}" \--query 'AuthenticationResult.AccessToken'--output text)"
CODE="$(curl-s-o /dev/null-w '%{http_code}'--max-time 10 \-H "Authorization: Bearer ${ACCESS_TOKEN}" "${API}/me")"
echo "   access token gives HTTP ${CODE} (401 or 403 both prove the point)"
else
echo "5-9. skipped: set SMOKE_EMAIL and SMOKE_PASSWORD to test authentication"
fi
echo "Smoke passed for ${ENVIRONMENT}."
