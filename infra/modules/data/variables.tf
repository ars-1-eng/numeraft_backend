variable "name_prefix" {
  description = "Resource name Prefix"
  type        = string
}

variable "point_in_time_recovery" {
  description = "Continuous backups with 35 day restore. True in prod, where the data is a customer's."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Blocks DeleteTable, including from Terraform. True in prod."
  type        = bool
  default     = false
}