variable "name_prefix" {
description = "Resource name prefix, for example numeraft-dev."
type= string
}
variable "alert_email" {
description = "Address that receives alarm and budget notifications."
type= string
}
variable "api_id" {
description = "HTTP API identifier to alarm on."
type= string
}
variable "function_names" {
description = "Lambda function names to create error and throttle alarms for."
type= list(string)
default= []

}
variable "monthly_budget_usd" {
description = "Monthly AWS spend budget for this environment."
type= number
default= 10

}
variable "api_5xx_threshold" {
description = "5xx responses in a five minute window before alarming."
type= number
default= 1

}
variable "api_latency_p99_ms" {
description = "p99 latency in milliseconds before alarming."
type= number
default= 3000
}