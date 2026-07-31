# Numeraft
Verified monthly client reports for marketing agencies.
Backend, infrastructure and delivery pipeline.- **Region:** `eu-west-1` (Dublin), EU data residency- **Stack:** Terraform, Node.js 24 on arm64 Lambda, API Gateway HTTP API,
Cognito, DynamoDB, S3, SQS, SES, Claude API- **Frontend:** Flutter Web, separate repository, owned by Suhani
## Layout
| Path | Contains |
|---|---|
| `infra/bootstrap` | Terraform state bucket, GitHub OIDC provider, deploy roles. Applied once. |
| `infra/modules` | Every real AWS resource. |
| `infra/envs/{dev,prod}` | Thin roots. Module calls and per-environment values only. |
| `services/src/lib` | Shared runtime helpers: env, logger, http, errors, handler wrapper. |
| `services/src/domain` | Pure business logic. No AWS imports, so it is unit testable. |
| `services/src/handlers` | One file per Lambda. Thin: parse, call domain, format. |
| `services/src/contracts` | Types shared with the Flutter app. Mirrors `docs/api-contract.md`. |
| `scripts` | Smoke tests and operational helpers. |
## Everyday commands
```bash
make build
make plan
make apply
make smoke
make plan ENV=prod
```
# typecheck, lint, test, bundle
# build then plan dev
# apply the saved plan
# assert the deployed API behaves
# same, against production
## Rules that are not negotiable
1. `infra/envs/*` contains no `resource` blocks. Resources live in modules.
2. Every AWS resource is created by Terraform. Nothing is clicked in the console
except read-only inspection.
3. `agency_id` comes from the verified JWT and nowhere else. Never from a path,
query string or body.
4. The LLM never produces a number. Every figure is computed in code, stored in
the Trust Ledger, and verified in the generated text before anything is sent.
5. Secret values never enter Terraform state. Terraform creates the secret,
you set the value with the AWS CLI once.
6. Every log group is declared in Terraform with a retention period.
7. Human review before send is the default. Auto-delivery is opt-in.