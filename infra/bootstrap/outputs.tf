output "state_bucket" {
  description = "S3 bucket used for Terraform state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "github_plan_role_arn" {
  description = "GitHub Actions Terraform plan role ARN."
  value       = aws_iam_role.github_plan.arn
}

output "github_apply_role_arn" {
  description = "GitHub Actions Terraform apply role ARN."
  value       = aws_iam_role.github_apply.arn
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}