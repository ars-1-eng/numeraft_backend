
# Where am I

variable "name_prefix" {
  type        = string
  description = "Resource name prefix,for example numeraft-dev"
}

variable "aws-region" {
  type        = string
  description = "Region,usedd to build the JWT issuer URL"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

# How should Authentication Behave

variable "allow_self_signup" {
  description = "Whether the internet may self-register. Keep false for a private beta."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Blocks deleting the user pool. TRUE IN PROD. Deleting a pool deletes every login."
  type        = bool
  default     = false
}

variable "mfa_configuration" {
  description = "OFF, OPTIONAL or ON. OPTIONAL lets a user enrol TOTP without locking anyone out."
  type        = string
  default     = "OPTIONAL"
  validation {
    condition     = contains(["OFF", "OPTIONAL", "ON"], var.mfa_configuration)
    error_message = "mfa_configuration must be OFF, OPTIONAL or ON."
  }
}


# What Data infrastructure do I depend on

variable "agencies_table_name" {
  description = "Agencies table name, passed to the trigger."
  type        = string
}
variable "users_table_name" {
  description = "Users table name, passed to the trigger."
  type        = string
}
variable "provision_identity_policy_json" {
  description = "IAM policy document allowing tenancy provisioning, from the data module."
  type        = string
}

# How should my Lambda run

variable "services_dist_dir" {
  description = "Path to built handler bundles."
  type        = string
}
variable "log_retention_days" {
  description = "CloudWatch Logs retention for the trigger."
  type        = number
  default     = 14
}
variable "log_level" {
  description = "Application log level for the trigger."
  type        = string
  default     = "INFO"

}
