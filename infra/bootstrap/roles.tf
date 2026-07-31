
// locals

locals {
repo = "${var.github_owner}/${var.github_repo}"
oidc_subjects_plan = [
"repo:${local.repo}:pull_request",
"repo:${local.repo}:ref:refs/heads/main",
]
oidc_subjects_apply = [
"repo:${local.repo}:environment:dev",
"repo:${local.repo}:environment:prod",
]
}

# trust

// trust plan

data "aws_iam_policy_document" "trust_plan"{
    statement {
      effect = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type = "Federated"
        identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      }

      condition {
  test     = "StringEquals"
  variable = "token.actions.githubusercontent.com:aud"
  values   = ["sts.amazonaws.com"]
}
condition{
    test = "StringEquals"
    values = local.oidc_subjects_plan
variable = "token.actions.githubusercontent.com:sub"
}

    }
}
// trust apply
data "aws_iam_policy_document" "trust_apply"{
    statement {
      effect = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type = "Federated"
        identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      }

      condition {
  test     = "StringEquals"
  variable = "token.actions.githubusercontent.com:aud"
  values   = ["sts.amazonaws.com"]
}
condition{
    test = "StringEquals"
    values = local.oidc_subjects_apply
variable = "token.actions.githubusercontent.com:sub"
}

    }
}
// github plan

resource "aws_iam_role" "github_plan"{
    assume_role_policy = data.aws_iam_policy_document.trust_plan
    name = "numeraft-github-plan"
description = "Read-only role for terraform plan on pull requests."
max_session_duration = 3600
}
// github apply
resource "aws_iam_role" "github_apply"{
    assume_role_policy = data.aws_iam_policy_document.trust_apply
    name = "numeraft-github-apply"
description = "Deploy role. Assumable only from a protected GitHub Environment."
max_session_duration = 3600
}

# plan role


// plan readonly 

resource "aws_iam_role_policy_attachment" "plan_readonly"{
    role = aws_iam_role.github_plan.name
policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}

// plan state

data "aws_iam_policy_document" "plan_state" {
statement {
sid = "StateAndLock"
effect = "Allow"
actions = [
"s3:GetObject",
"s3:PutObject",
"s3:DeleteObject",
"s3:ListBucket",
]
resources = [
aws_s3_bucket.terraform_state.arn,
"${aws_s3_bucket.terraform_state.arn}/*",
]
}
}
resource "aws_iam_role_policy" "plan_state" {
name = "terraform-state"
role = aws_iam_role.github_plan.id
policy = data.aws_iam_policy_document.plan_state.json
}
//

resource "aws_iam_role_policy_attachment" "apply_power" {
role = aws_iam_role.github_apply.name
policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "apply_guardrails" {
statement {
sid = "DenyReadingSecretValues"
effect = "Deny"
actions = ["secretsmanager:GetSecretValue"]
resources = ["*"]
}
statement {
sid = "ProtectStateBucket"
effect = "Deny"
actions = ["s3:DeleteBucket", "s3:PutBucketVersioning"]
resources = [aws_s3_bucket.terraform_state.arn]
}
statement {
sid= "ProtectOwnTrustPolicies"
effect = "Deny"
actions = [
"iam:UpdateAssumeRolePolicy",
"iam:DeleteRole",
"iam:PutRolePolicy",
]
resources = [
aws_iam_role.github_plan.arn,
aws_iam_role.github_apply.arn,
]
}
}
resource "aws_iam_role_policy" "apply_guardrails" {
name = "guardrails"
role= aws_iam_role.github_apply.id
policy = data.aws_iam_policy_document.apply_guardrails.json
}

data "aws_iam_policy_document" "apply_iam" {
statement {
sid= "ManageNumeraftServiceRoles"
effect = "Allow"
actions = [
"iam:CreateRole",
"iam:DeleteRole",
"iam:GetRole",
"iam:TagRole",
"iam:UntagRole",
"iam:UpdateAssumeRolePolicy",
"iam:PutRolePolicy",
"iam:GetRolePolicy",
"iam:DeleteRolePolicy",
"iam:AttachRolePolicy",
"iam:DetachRolePolicy",
"iam:ListRolePolicies",
"iam:ListAttachedRolePolicies",
"iam:ListInstanceProfilesForRole",
"iam:PassRole",
]
resources = [
"arn:${data.aws_partition.current.partition}:iam::${var.aws_account_id}:role/numeraft-dev-*",
"arn:${data.aws_partition.current.partition}:iam::${var.aws_account_id}:role/numeraft-prod-*",
]
}
}
resource "aws_iam_role_policy" "apply_iam" {
name= "service-role-management"
role= aws_iam_role.github_apply.id
policy = data.aws_iam_policy_document.apply_iam.json
}