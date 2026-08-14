output "user_pool_id" {
  description = "Cognito user pool ID. Suhani needs this."
  value       = aws_cognito_user_pool.main.id
}
output "user_pool_arn" {
  description = "Cognito user pool ARN."
  value       = aws_cognito_user_pool.main.arn
}
output "user_pool_client_id" {
  description = "App client ID. Suhani needs this. Also the JWT audience."
  value       = aws_cognito_user_pool_client.web.id
}
output "jwt_issuer" {
  description = "Issuer URL for the API Gateway JWT authorizer."
  value       = "https://cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
}

data "aws_region" "current" {}
output "bootstrap_policy_json" {
  description = "Policy for POST /me/bootstrap: provision records and write tenancy attributes."
  value       = data.aws_iam_policy_document.bootstrap.json
}
output "trigger_function_name" {
  description = "Post-confirmation trigger function name, for log tailing."
  value       = module.post_confirmation.function_name
}