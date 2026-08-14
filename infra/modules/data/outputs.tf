output "agencies_table_name" {
  description = "DynamoDB table holding agency records."
  value       = aws_dynamodb_table.agencies.name
}
output "agencies_table_arn" {
  description = "ARN of the agencies table."
  value       = aws_dynamodb_table.agencies.arn
}
output "users_table_name" {
  description = "DynamoDB table mapping Cognito subs to agencies."
  value       = aws_dynamodb_table.users.name
}
output "users_table_arn" {
  description = "ARN of the users table."
  value       = aws_dynamodb_table.users.arn
}
output "read_identity_policy_json" {
  description = "Least-privilege read policy for GET /me."
  value       = data.aws_iam_policy_document.read_identity.json
}
output "provision_identity_policy_json" {
  description = "Least-privilege write policy for tenancy provisioning."
  value       = data.aws_iam_policy_document.provision_identity.json
}