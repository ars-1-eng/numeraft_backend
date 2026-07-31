#!/usr/bin/env bash
# Asserts that the deployed API behaves as the contract promises.
# Usage: ./scripts/smoke.sh [dev|prod]
set-euo pipefail
ENVIRONMENT="${1:-dev}"
ROOT="infra/envs/${ENVIRONMENT}"
if [ !-d "$ROOT" ]; then
echo "No such environment: ${ENVIRONMENT}" >&2
exit 1
fi
API="$(terraform-chdir="$ROOT" output-raw api_base_url)"
echo "Smoke testing ${ENVIRONMENT} at ${API}"
fail() { echo "  FAIL: $1" >&2; exit 1; }
# ---------------------------------------------------------------- 1. health
echo "1. GET /health returns 200 and the documented shape"
BODY="$(curl-fsS--max-time 10 "${API}/health")" || fail "health did not return 2xx"
echo "$BODY" | python3-<<'PY' || fail "health body did not match the contract"
import json, sys, re
d = json.load(sys.stdin)
assert d["status"] == "ok", d
assert d["service"] == "numeraft-api", d
assert isinstance(d["environment"], str) and d["environment"], d
assert re.match(r"^\d{4}-\d{2}-\d{2}T[\d:.]+Z$", d["timestamp"]), d
assert d["requestId"], d
PY
# ------------------------------------------------------- 2. request id header
echo "2. the response carries x-request-id"
curl-fsS-D--o /dev/null--max-time 10 "${API}/health" \
| tr 'A-Z' 'a-z' | grep-q '^x-request-id:' || fail "x-request-id header missing"
# ------------------------------------------------------------ 3. unknown route
echo "3. an unknown route returns 404, not 500"
CODE="$(curl-s-o /dev/null-w '%{http_code}'--max-time 10 "${API}/definitely-not-a-route")"
[ "$CODE" = "404" ] || fail "expected 404 for an unknown route, got ${CODE}"
# -------------------------------------------------------------- 4. CORS is set
echo "4. CORS does not allow a wildcard origin"
ALLOWED="$(curl-s-D--o /dev/null--max-time 10 \-H 'Origin: https://evil.example' \-H 'Access-Control-Request-Method: GET' \-X OPTIONS "${API}/health" \
| tr 'A-Z' 'a-z' | grep '^access-control-allow-origin:' || true)"
echo "$ALLOWED" | grep-q '\*' && fail "the API allows a wildcard CORS origin"
echo "Smoke passed for ${ENVIRONMENT}."