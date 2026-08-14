
module "post_confirmation" {
  source              = "../lambda-fn"
  account_id          = var.account_id
  name                = "${var.name_prefix}-post_confirmation"
  source_dir          = "${var.services_dist_dir}/post_confirmation"
  memory_mb           = 512
  log_retention_days  = var.log_retention_days
  extra_policy_json   = var.provision_identity_policy_json
  timeout_seconds     = 10
  log_level           = var.log_level
  attach_extra_policy = true

  environment_variables = {
    AGENCIES_TABLE = var.agencies_table_name

    USERS_TABLE = var.users_table_name
  }
  tags = { Component = "identity" }

}

data "aws_iam_policy_document" "trigger_cognito" {
  statement {
    sid       = "WriteTenancyAttributes"
    actions   = ["cognito-idp:AdminUpdateUserAttributes"]
    effect    = "Allow"
    resources = [aws_cognito_user_pool.main.arn]
  }
}

resource "aws_iam_role_policy" "trigger_cognito" {
  name   = "cognito"
  role   = module.post_confirmation.role_name
  policy = data.aws_iam_policy_document.trigger_cognito.json
}

resource "aws_lambda_permission" "cognito_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

data "aws_iam_policy_document" "bootstrap" {
  source_policy_documents = [var.provision_identity_policy_json]
  statement {
    sid = "WriteTenancyAttributes"

    effect = "Allow"

    actions   = ["cognito-idp:AdminUpdateUserAttributes"]
    resources = [aws_cognito_user_pool.main.arn]
  }
}
