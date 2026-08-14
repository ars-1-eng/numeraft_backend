# Adopt the existing Terraform state bucket into bootstrap state.

import {
  to = aws_s3_bucket.terraform_state
  id = "numeraft-tfstate-108742335441-eu-west-1"
}

import {
  to = aws_iam_openid_connect_provider.github_actions
  id = "arn:aws:iam::108742335441:oidc-provider/token.actions.githubusercontent.com"
}
