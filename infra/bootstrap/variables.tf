variable "aws_region" {
  description = "AWS region for Numeraft. EU data residency requires eu-west-1."
  type        = string
  default     = "eu-west-1"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. Terraform refuses to run elsewhere."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
  }
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name."
  type        = string
  default     = "numeraft_backend"
}