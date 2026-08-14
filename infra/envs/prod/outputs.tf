output "api_base_url" {
  description = "Base URL of the Numeraft HTTP API for this environment."
  value       = module.api.api_endpoint
}
output "health_url" {
  description = "Public health-check endpoint."
  value       = "${module.api.api_endpoint}/health"
}
output "api_id" {
  description = "HTTP API identifier."
  value       = module.api.api_id
}
output "function_names" {
  description = "Lambda functions deployed in this environment."
  value       = module.api.function_names
}
output "access_log_group" {
  description = "API Gateway access log group."
  value       = module.api.access_log_group
}
output "alerts_topic_arn" {
  description = "SNS topic every alarm publishes to."
  value       = module.observability.alerts_topic_arn
}


output "user_pool_id" {
description = "Cognito user pool ID. Send to Suhani."
value= module.identity.user_pool_id
}
output "user_pool_client_id" {
description = "Cognito app client ID. Send to Suhani."
value= module.identity.user_pool_client_id
}
output "jwt_issuer" {
description = "Issuer URL, useful when debugging a 401."
value= module.identity.jwt_issuer
}
output "agencies_table_name" {
description = "Agencies table, for CLI inspection."
value= module.data.agencies_table_name
}
output "users_table_name" {
description = "Users table, for CLI inspection."
value= module.data.users_table_name
}
output "trigger_function_name" {
description = "Post-confirmation trigger, for log tailing."
value= module.identity.trigger_function_name
}
