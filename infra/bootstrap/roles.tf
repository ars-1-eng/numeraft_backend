locals {
  repo = "${var.github_owner}/${var.github_repo}"

  # Allowed identities for Terraform plans.
  oidc_subjects_plan = [
    "repo:${local.repo}:pull_request",
    "repo:${local.repo}:ref:refs/heads/main",
  ]

  # Allowed identities for Terraform applies.
  # The GitHub workflow must use environment: dev or environment: prod.
  oidc_subjects_apply = [
    "repo:${local.repo}:environment:dev",
    "repo:${local.repo}:environment:prod",
  ]
}

# -------------------------------------------------------------------
# Trust policy for the Terraform plan role
# -------------------------------------------------------------------

data "aws_iam_policy_document" "trust_plan" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn,
      ]
    }

    # GitHub's token must be intended for AWS STS.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only this repository's pull requests/main branch may assume it.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.oidc_subjects_plan
    }
  }
}

# -------------------------------------------------------------------
# Trust policy for the Terraform apply role
# -------------------------------------------------------------------

data "aws_iam_policy_document" "trust_apply" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only protected GitHub environments may assume the deploy role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.oidc_subjects_apply
    }
  }
}

# -------------------------------------------------------------------
# GitHub Terraform plan role
# -------------------------------------------------------------------

resource "aws_iam_role" "github_plan" {
  name                 = "numeraft-github-plan"
  description          = "Read-only role for Terraform plans."
  max_session_duration = 3600

  # Important: aws_iam_policy_document must be converted to JSON.
  assume_role_policy = data.aws_iam_policy_document.trust_plan.json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.github_plan.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/ReadOnlyAccess"
}

# Terraform plan needs to read state and temporarily create/delete
# the S3 lock file.
data "aws_iam_policy_document" "plan_state" {
  statement {
    sid    = "ListStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn,
    ]
  }

  statement {
    sid    = "ReadWriteStateAndLockObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state"
  role   = aws_iam_role.github_plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

# -------------------------------------------------------------------
# GitHub Terraform apply role
# -------------------------------------------------------------------

resource "aws_iam_role" "github_apply" {
  name                 = "numeraft-github-apply"
  description          = "Deploy role for protected GitHub environments."
  max_session_duration = 3600

  assume_role_policy = data.aws_iam_policy_document.trust_apply.json
}

# PowerUserAccess covers application services such as Lambda,
# API Gateway, CloudWatch, SNS and S3, but not general IAM administration.
resource "aws_iam_role_policy_attachment" "apply_power" {
  role       = aws_iam_role.github_apply.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/PowerUserAccess"
}

# -------------------------------------------------------------------
# Guardrails for the deploy role
# -------------------------------------------------------------------

data "aws_iam_policy_document" "apply_guardrails" {
  statement {
    sid       = "DenyReadingSecretValues"
    effect    = "Deny"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }

  statement {
    sid    = "ProtectStateBucket"
    effect = "Deny"

    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketVersioning",
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn,
    ]
  }

  statement {
    sid    = "ProtectGitHubRoles"
    effect = "Deny"

    actions = [
      "iam:UpdateAssumeRolePolicy",
      "iam:DeleteRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]

    resources = [
      aws_iam_role.github_plan.arn,
      aws_iam_role.github_apply.arn,
    ]
  }
}

resource "aws_iam_role_policy" "apply_guardrails" {
  name   = "guardrails"
  role   = aws_iam_role.github_apply.id
  policy = data.aws_iam_policy_document.apply_guardrails.json
}

# -------------------------------------------------------------------
# Limited IAM management for Numeraft application Lambda roles
# -------------------------------------------------------------------

data "aws_iam_policy_document" "apply_iam" {
  statement {
    sid    = "ManageNumeraftServiceRoles"
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
  name   = "service-role-management"
  role   = aws_iam_role.github_apply.id
  policy = data.aws_iam_policy_document.apply_iam.json
}