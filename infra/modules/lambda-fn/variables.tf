variable "name" {
  description = "Full function name, already prefixed. Example: numeraft-dev-health."
  type        = string
}
variable "source_dir" {
  description = "Directory holding the built bundle (index.mjs plus package.json)."
  type        = string
}
variable "account_id" {
  description = "Account ID, used in the assume-role source-account condition."
  type        = string
}
variable "handler" {
  description = "Lambda handler entry point."
  type        = string
  default     = "index.handler"

}
variable "runtime" {
  description = "Lambda managed runtime identifier."
  type        = string
  default     = "nodejs24.x"

}
variable "memory_mb" {
  description = "Memory in MB. Lambda scales CPU with memory, so more memory is often cheaper for CPU bound work."
  type        = number
  default     = 512

}
variable "timeout_seconds" {
  description = "Function timeout. API Gateway gives up at 29 seconds regardless."
  type        = number
  default     = 10

}
variable "environment_variables" {
  description = "Environment variables for the function. Never secret values."
  type        = map(string)
  default     = {}

}
variable "log_retention_days" {
  description = "CloudWatch Logs retention. Never leave a log group unretained."
  type        = number
  default     = 14

}
variable "log_level" {
  description = "Application log level: DEBUG, INFO, WARN or ERROR."
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "log_level must be DEBUG, INFO, WARN or ERROR."
  }
}
variable "extra_policy_json" {
  description = "Optional IAM policy document JSON for resources this function needs."
  type        = string
  default     = null
}
variable "reserved_concurrency" {
  description = "-1 leaves the function unreserved. A positive value caps blast radius and spend."
  type        = number
  default     = -1
}
variable "tracing" {
  description = "Enable AWS X-Ray active tracing."
  type        = bool
  default     = true

}
variable "tags" {
  description = "Extra tags merged with the provider default tags."
  type        = map(string)
  default     = {}
}
variable "attach_extra_policy" {
  description = "Whether this Lambda should receive an additional IAM policy."
  type        = bool
  default     = false
}