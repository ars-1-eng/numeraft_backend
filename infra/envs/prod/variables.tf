
variable "app_name" {
  description = "Application name used in every resource name and tag."
  type        = string
  default     = "numeraft"
}

variable "environment" {
  description = "Deployment environment. Part of every resource name."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "aws_region" {
  description = "AWS region for all regional resources. EU residency requires eu-west-1."
  type        = string
  default     = "eu-west-1"
}

variable "aws_account_id" {
  description = "Expected AWS account. Terraform refuses to run against any other."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be exactly 12 digits."
  }
}

variable "alert_email" {
  description = "Address for alarm and budget notifications. Confirm the SNS subscription email."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly AWS budget for this environment."
  type        = number
  default     = 60
}

variable "cors_origins" {
  description = "Browser origins allowed to call the API."
  type        = list(string)
  default     = ["https://app.numeraft.com"]
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for this environment."
  type        = number
  default     = 90
}

variable "log_level" {
  description = "Application log level for every handler."
  type        = string
  default     = "INFO"
}

variable "api_throttle_burst" {
  description = "Stage burst limit. Low in dev, to catch your own loops."
  type        = number
  default     = 100
}

variable "api_throttle_rate" {
  description = "Stage steady-state requests per second."
  type        = number
  default     = 50
}

variable "allow_self_signup" {
description = "Whether the internet may self-register. False for the private beta."
type= bool
default= false

}
variable "mfa_configuration" {
description = "Cognito MFA setting: OFF, OPTIONAL or ON."
type= string
default="OPTIONAL"
}