output "api_base_url" {
description = "Base URL of the Numeraft HTTP API for this environment."
value= module.api.api_endpoint
}
output "health_url" {
description = "Public health-check endpoint."
value= "${module.api.api_endpoint}/health"
}
output "api_id" {
description = "HTTP API identifier."
value= module.api.api_id
}
output "function_names" {
description = "Lambda functions deployed in this environment."
value= module.api.function_names
}
output "access_log_group" {
description = "API Gateway access log group."
value= module.api.access_log_group
}
output "alerts_topic_arn" {
description = "SNS topic every alarm publishes to."
value= module.observability.alerts_topic_arn
}