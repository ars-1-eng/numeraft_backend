#!/usr/bin/env bash
# Creates a confirmed beta user with a permanent password.
#
# admin-create-user does not fire PostConfirmation.
# The user receives tenancy later through POST /me/bootstrap.
#
# Usage:
#   ./scripts/create-user.sh dev someone@agency.com
# or:
#   ./scripts/create-user.sh dev someone@agency.com 'StrongPassword1'

set -euo pipefail

ENVIRONMENT="${1:?environment required (dev|prod)}"
EMAIL="${2:?email required}"
PASSWORD="${3:-}"

if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Environment must be dev or prod."
  exit 1
fi

if [[ -z "$PASSWORD" ]]; then
  read -rsp "Permanent password: " PASSWORD
  echo
fi

POOL="$(terraform -chdir="infra/envs/${ENVIRONMENT}" output -raw user_pool_id)"

echo "Creating ${EMAIL} in ${POOL}"

aws cognito-idp admin-create-user \
  --user-pool-id "$POOL" \
  --username "$EMAIL" \
  --message-action SUPPRESS \
  --user-attributes \
    "Name=email,Value=${EMAIL}" \
    "Name=email_verified,Value=true" \
  >/dev/null

aws cognito-idp admin-set-user-password \
  --user-pool-id "$POOL" \
  --username "$EMAIL" \
  --password "$PASSWORD" \
  --permanent

echo "Created and confirmed."

aws cognito-idp admin-get-user \
  --user-pool-id "$POOL" \
  --username "$EMAIL" \
  --query 'UserAttributes[?starts_with(Name, `custom:`)]' \
  --output table || true

echo
echo "Next: sign in -> POST /me/bootstrap -> refresh token -> GET /me"
