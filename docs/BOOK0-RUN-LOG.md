# Book 0 — Run Log

What was found, what was fixed, and the exact sequence used to actually stand
up Book 0's infrastructure in AWS account `108742335441` (region
`eu-west-1`). Read this once, then use it as the reference for "why does this
file look like that" and "what do I still need to do."

Status at the end of this session: **bootstrap, dev, and prod are all applied
and passing all of Book 0 Part 6's verification checks**, with two manual
follow-ups left for you (see [Part C](#c-what-you-still-need-to-do)).

---

## A. What was actually wrong

You'd already done real work before this session (bootstrap partially
initialized, an import plan drafted, dev/prod module files written). Two
categories of problems were found and fixed.

### A.1 — Files with lost formatting

Four files had lost whitespace that changes their meaning (not cosmetic —
these would have failed outright):

| File | What was wrong | Effect if unfixed |
|---|---|---|
| `Makefile` | Every recipe line lost its leading TAB and the spaces before flags (`terraform-chdir=...`, `mkdir-p`, `rm-rf`) | `make` fails immediately with "missing separator" on every target |
| `scripts/smoke.sh` | Same pattern (`set-euo pipefail`, `curl-fsS--max-time`) | Script fails on line 1 |
| `.github/workflows/ci.yml` | Only the preamble (`on:`, `permissions:`, `concurrency:`, `env:`, lines 1–16) lost its indentation | In YAML this isn't cosmetic: `on:` becomes an empty mapping, so the workflow would never trigger on pull requests |
| `.github/workflows/deploy-prod.yml` | Mangled throughout — missing newlines between steps, no indentation at all | Fails to parse as YAML |

All four were rewritten from verified-correct text. `deploy-dev.yml` and
`.tflint.hcl` had the same kind of damage checked for and were fine (HCL
doesn't care about indentation, so `.tflint.hcl`'s lost indentation was
harmless).

### A.2 — Real bugs in the Terraform itself

These weren't formatting — they were typos that would have failed at
`validate`, `plan`, or (worse) silently misconfigured a live IAM policy:

| File | Bug | What it would have done |
|---|---|---|
| `infra/modules/lambda-fn/main.tf` | `role = aws.iam_role.fn.id` (dot instead of underscore) | `terraform plan` error: reference to undeclared resource `aws.iam_role` |
| same file | Lambda's trust policy: `Principle` instead of `Principal`, `lambda:amazonaws.com` instead of `lambda.amazonaws.com`, `Conditions` instead of `Condition`, and a missing `Version` key | Every Lambda's IAM role would fail AWS's policy validation, or — worse — create a role Lambda can never assume (`InvalidParameterValueException: The role defined for the function cannot be assumed by Lambda`) |
| `infra/modules/http-api/locals.tf` | Called `regexreplace(...)` — **not a real Terraform function** (the real one is `replace()` with a regex delimited by `/.../`) | `terraform validate` error: "Call to unknown function" |
| `infra/modules/http-api/authorizer.tf` | JWT authorizer name hardcoded to `"example-authorizer"` instead of `"${var.name_prefix}-jwt"` | Harmless in Book 0 (this resource has `count = 0` while `jwt_issuer` is null), but would bite in Book 1 |
| `infra/modules/http-api/api.tf` | CORS config was missing `expose_headers = ["x-request-id"]` | Browser JS could never read the `x-request-id` response header — breaks the "customer pastes this ID into a support message" flow from a real frontend (curl-based smoke tests wouldn't catch this, since curl ignores CORS) |
| `infra/envs/prod/providers.tf` | **Completely empty file** (0 bytes) | `terraform init` warns "no backend configuration set"; every `plan`/`apply` in prod would have used purely local state instead of the shared S3 backend |
| `infra/envs/prod/outputs.tf` | **Completely empty file** (0 bytes) | No `api_base_url`/`health_url`/etc. outputs — `smoke.sh prod` would have had nothing to read |
| `infra/envs/prod/terraform.tfvars.example` | Empty | Cosmetic — filled in for completeness |
| `scripts/smoke.sh` (its own logic, not a formatting issue) | `echo "$BODY" | python3 - <<'PY' ... PY` — piping into a command that *also* has a heredoc attached to its stdin. The heredoc wins; `python3 -` reads its **program** from the heredoc, so by the time the script calls `json.load(sys.stdin)`, stdin is already at EOF and the piped `$BODY` was discarded | `JSONDecodeError: Expecting value: line 1 column 1` on every run, even against a perfectly healthy API. Fixed by using `python3 -c '...'` (program passed as an argument, so stdin stays free for the piped body) |

None of the actual product/business logic (`services/src/**`) had problems —
`npm run check` passed cleanly (0 typecheck errors, 8/8 tests, 5 lint
*warnings* which the book's own `eslint.config.mjs` treats as non-fatal).

### A.3 — Placeholder values and one mismatch

- `infra/envs/dev/ci.tfvars` and `infra/envs/prod/ci.tfvars` both still had
  `aws_account_id = "000000000000"`. Left alone, every CI plan/apply would
  have been refused by the provider's `allowed_account_ids` guard. Fixed to
  `108742335441`.
- `infra/envs/dev/backend.hcl` pointed at S3 key `dev/terraform.tfstate`
  (where your real state already lived), but all three GitHub workflows
  hardcode `envs/dev/terraform.tfstate` / `envs/prod/terraform.tfstate` (the
  book's original convention). Left alone, CI would have initialized against
  an empty state at a different key and tried to recreate everything that
  already exists. **Fixed by standardizing on the book's convention**:
  migrated dev's state with `terraform init -migrate-state` (a pure location
  move, verified with a `0 changes` plan immediately after), and gave prod
  that same convention from the start.
- A leftover, Terraform-**un**managed IAM role `numeraft-github-actions`
  existed from before the bootstrap split — `PowerUserAccess` attached,
  trust policy scoped to the wrong repo name (`ars-1-eng/numeraft`, missing
  `_backend`). Superseded by the new scoped `numeraft-github-plan` /
  `numeraft-github-apply` roles. **Deleted** (detached the managed policy,
  deleted the one inline policy, deleted the role — confirmed gone via
  `NoSuchEntity`).

---

## B. What was actually run, in order

All commands used AWS CLI profile `numeraft-admin` (account `108742335441`).
**`make` is not installed in this environment** — the raw commands below are
exactly what each Makefile target runs; once you install Make (or use WSL),
`make plan`, `make apply ENV=prod`, etc. work identically.

### B.1 — Bootstrap (`infra/bootstrap`)

```bash
terraform init -backend-config=backend.hcl -reconfigure
terraform plan -out=tfplan   # → 2 to import, 13 to add, 0 to change, 0 to destroy
terraform apply tfplan       # → Apply complete! Resources: 2 imported, 13 added, 0 changed, 0 destroyed.
```

Adopted your pre-existing state bucket and GitHub OIDC provider into
Terraform's state, and created the two scoped GitHub Actions roles, the
bucket policy, lifecycle rule, SSE (AES256), and public-access block.
Immediately re-planned: **No changes.**

Then, out of band (not Terraform-managed):
```bash
aws iam detach-role-policy --role-name numeraft-github-actions \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
aws iam delete-role-policy --role-name numeraft-github-actions \
  --policy-name numeraft-dev-role-management
aws iam delete-role --role-name numeraft-github-actions
```

### B.2 — Dev: migrate state key, destroy the old flat stack

```bash
# backend.hcl key changed to envs/dev/terraform.tfstate
terraform init -backend-config=backend.hcl -migrate-state   # answered "yes" to copy state

terraform plan -destroy -out=destroy.tfplan   # → 0 to add, 0 to change, 11 to destroy
terraform apply destroy.tfplan                # → Apply complete! Resources: 0 added, 0 changed, 11 destroyed.
```

This removed the pre-refactor resources that were still live: Lambda
`numeraft-dev-health`, API `numeraft-dev-http`, IAM role
`numeraft-dev-health-exec`, budget `numeraft-dev-monthly`, and the two
Terraform-managed log groups. Confirmed via direct AWS CLI calls (not just
`terraform state list`) that all of them were actually gone.

One more manual cleanup — the **unmanaged** Lambda log group (Defect 1's
orphan, retention `None`, never in any Terraform state) had to be deleted
*before* the new stack, since the new module declares a log group with the
exact same name:
```bash
aws logs delete-log-group --log-group-name /aws/lambda/numeraft-dev-health
```

### B.3 — Dev: apply the new module-based stack

```bash
cd services && npm run check   # 0 errors, 8/8 tests, build → dist/health (58 KB)
cd infra/envs/dev
terraform plan -var-file=terraform.tfvars -out=tfplan    # → 18 to add, 0 to change, 0 to destroy
terraform apply tfplan                                    # → Apply complete! Resources: 18 added.
```

### B.4 — Prod: first-ever apply

```bash
# created infra/envs/prod/terraform.tfvars and backend.hcl (didn't exist yet)
# fixed the two empty files (providers.tf, outputs.tf) — see A.2
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars -out=tfplan   # → 18 to add, 0 to change, 0 to destroy
terraform apply tfplan                                   # → Apply complete! Resources: 18 added.
```

### B.5 — Verification (Book 0 Part 6, all 10 checks)

| # | Check | Result |
|---|---|---|
| 1 | `./scripts/smoke.sh dev` | **Pass** — all 4 assertions |
| 2 | `./scripts/smoke.sh prod` | **Pass** — all 4 assertions |
| 3 | `terraform plan` in dev → No changes | **Pass** |
| 4 | `terraform plan` in prod → No changes | **Pass** |
| 5 | Logs land in `/aws/lambda/numeraft-dev-health` with `requestId`/`durationMs` fields | **Pass** |
| 6 | No `numeraft*` log group with `retentionInDays: null` | **Pass** (empty result) |
| 7 | Wrong `aws_account_id` refused before touching resources | **Pass** — `Error: AWS account ID not allowed: 108742335441` |
| 8 | Concurrent `terraform plan` blocked by the S3 lock | **Pass** — second process errored with a lock-acquisition failure under a 2s timeout |
| 9 | SNS alarm path (`set-alarm-state` → email) | **Forced successfully** — alarm went to `ALARM` state. **Action needed from you**: both the dev topic (recreated during check 10, see below) and the prod topic still show `PendingConfirmation` on the email subscription. Check `arssoftware1@gmail.com` and click both confirmation links, or every alarm fires into nothing. |
| 10 | `terraform destroy` in dev leaves zero resources, then rebuild | **Pass** — destroyed 18/18, confirmed zero survivors via direct AWS CLI (Lambda, log groups, API, IAM role, budget, SNS topic all absent), then re-applied cleanly (18 added again) |

Because check 10 recreated dev's SNS topic (new ARN), **dev's alert email
subscription needs re-confirming too** — it's back to `PendingConfirmation`.

---

## C. What you still need to do

### C.1 — Confirm the SNS email subscriptions (required for alarms to work)

Check **arssoftware1@gmail.com** for two AWS SNS confirmation emails (dev and
prod) and click "Confirm subscription" on both. Verify with:
```bash
aws sns list-subscriptions-by-topic --region eu-west-1 \
  --topic-arn "$(terraform -chdir=infra/envs/dev output -raw alerts_topic_arn)"
aws sns list-subscriptions-by-topic --region eu-west-1 \
  --topic-arn "$(terraform -chdir=infra/envs/prod output -raw alerts_topic_arn)"
```
Both should show a real ARN instead of `PendingConfirmation`.

### C.2 — Wire up GitHub Actions CI (I have no `gh` CLI/token in this environment — this is manual)

**Repository secrets** (Settings → Secrets and variables → Actions) on
`ars-1-eng/numeraft_backend`:

| Secret | Value |
|---|---|
| `AWS_PLAN_ROLE_ARN` | `arn:aws:iam::108742335441:role/numeraft-github-plan` |
| `AWS_APPLY_ROLE_ARN` | `arn:aws:iam::108742335441:role/numeraft-github-apply` |
| `TF_STATE_BUCKET` | `numeraft-tfstate-108742335441-eu-west-1` |
| `ALERT_EMAIL` | `arssoftware1@gmail.com` |

**Environments** (Settings → Environments):
- `dev` — create it, no protection rules.
- `prod` — create it, add yourself as a **required reviewer**, add a **5
  minute wait timer**. This is the actual approval gate for production
  deploys (the bootstrap trust policy only allows `AssumeRoleWithWebIdentity`
  from a job running inside one of these named Environments).

**Branch protection** on `main` (Settings → Rules or Branches):
- Require a pull request before merging.
- Require status checks: `services`, `terraform (dev)`, `terraform (prod)`.
- Block force pushes.

Once that's done, open a PR — you should see two "Terraform plan" comments
(dev and prod), both reporting **No changes** (proof that your local applies
and CI's view of the world agree). Merging to `main` will run
`deploy-dev.yml` automatically; `deploy-prod.yml` only runs when you manually
dispatch it and type `deploy prod` into the confirmation input.

### C.3 — Optional cleanup

- `install make` (e.g. via `choco install make` or use WSL) if you want to
  use the `Makefile` targets directly rather than the raw commands in
  section B.
- The old S3 state object `dev/terraform.tfstate` (pre-migration key) is
  still sitting in the bucket, now unused. Harmless, but you can delete it:
  `aws s3 rm s3://numeraft-tfstate-108742335441-eu-west-1/dev/terraform.tfstate`
  (and its version history via `s3api delete-object --version-id ...` if you
  want it fully gone, not just hidden).
- Review and commit the changes — nothing was committed to git during this
  session. `git status` currently shows the files listed in section A as
  modified, plus new files (`infra/bootstrap/imports.tf`,
  `.terraform.lock.hcl` in three roots, `bootstrap-import-plan.txt`). The
  three `.terraform.lock.hcl` files **should** be committed (the book's
  `.gitignore` explicitly un-ignores them) — everything else under
  `.terraform/` should not be, and already isn't tracked.

---

## D. Live resource inventory

| Root | Output | Value |
|---|---|---|
| bootstrap | `state_bucket` | `numeraft-tfstate-108742335441-eu-west-1` |
| bootstrap | `github_plan_role_arn` | `arn:aws:iam::108742335441:role/numeraft-github-plan` |
| bootstrap | `github_apply_role_arn` | `arn:aws:iam::108742335441:role/numeraft-github-apply` |
| dev | `health_url` | `https://hscgzekq2f.execute-api.eu-west-1.amazonaws.com/health` |
| dev | `alerts_topic_arn` | `arn:aws:sns:eu-west-1:108742335441:numeraft-dev-alerts` |
| prod | `health_url` | `https://y0j0n1qc54.execute-api.eu-west-1.amazonaws.com/health` |
| prod | `alerts_topic_arn` | `arn:aws:sns:eu-west-1:108742335441:numeraft-prod-alerts` |

Both `health_url`s currently return the documented contract:
```json
{"status":"ok","service":"numeraft-api","environment":"dev|prod","timestamp":"...","requestId":"..."}
```

Book 0's four "done when" checks (Part 1) all hold: both health endpoints
respond correctly, both env roots plan clean, the CI plan-on-PR / apply-on-
merge pipeline is code-complete (pending the manual GitHub setup in C.2), and
`terraform destroy` in dev was proven to leave nothing behind.
