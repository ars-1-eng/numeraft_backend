output "api_id" {
  description = "HTTP API identifier."
  value       = aws_apigatewayv2_api.http.id
}
output "api_endpoint" {
  description = "Base URL of the default stage."
  value       = aws_apigatewayv2_api.http.api_endpoint
}
output "execution_arn" {
  description = "Execution ARN, for building further invoke permissions."
  value       = aws_apigatewayv2_api.http.execution_arn
}
output "access_log_group" {
  description = "Access log group name."
  value       = aws_cloudwatch_log_group.access.name
}
output "function_names" {
  description = "Every Lambda created by this module, for alarm wiring."
  value = [for
  key in keys(var.routes) : module.fn[key].function_name]
}
output "function_roles" {
  description = "Map of route key to execution role name, for out-of-band policies."
  value = { for
  key in keys(var.routes) : key => module.fn[key].role_name }
}