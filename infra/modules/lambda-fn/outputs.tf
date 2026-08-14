output "arn" {
  description = "Function ARN."
  value       = aws_lambda_function.fn.arn

}
output "invoke_arn" {
  description = "ARN used by API Gateway integrations."
  value       = aws_lambda_function.fn.invoke_arn

}
output "function_name" {
  description = "Function name."
  value       = aws_lambda_function.fn.function_name

}
output "role_name" {
  description = "Execution role name, for attaching further policies out of band."
  value       = aws_iam_role.fn.name

}
output "role_arn" {
  description = "Execution role ARN."
  value       = aws_iam_role.fn.arn

}
output "log_group" {
  description = "CloudWatch Logs group name."
  value       = aws_cloudwatch_log_group.fn.name

}