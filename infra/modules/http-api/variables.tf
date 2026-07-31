variable "name_prefix" {
description = "Resource name prefix, for example numeraft-dev."
type= string
}
variable "account_id" {
description = "AWS account ID."
type= string
}
variable "services_dist_dir" {
description = "Path to the built handler bundles, usually services/dist."
type= string
}
variable "cors_origins" {
description = "Browser origins allowed to call the API. Never use * anywhere."
type= list(string)
validation {
condition= !contains(var.cors_origins, "*")
error_message = "A wildcard CORS origin is never acceptable for an authenticated API."
}
}
variable "throttle_burst" {
description = "Stage-level burst limit."
type= number
default= 20

}
variable "throttle_rate" {
description = "Stage-level steady-state requests per second."
type= number
default= 10

}
variable "detailed_metrics" {
description = "Per-route CloudWatch metrics. Useful while building, billed per metric."
type= bool
default= false

}
variable "log_retention_days" {
description = "Retention for access logs and every function's logs."
type= number
default= 14

}
variable "log_level" {
description = "Application log level passed to every handler."
type= string
default= "INFO"

}
variable "jwt_issuer" {
description = "Cognito issuer URL. Null in Book 0, set in Book 1, which enables the authorizer."
type= string
default= null

}
variable "jwt_audiences" {
description = "Allowed audiences, which is the Cognito app client ID list."
type= list(string)
default=[]
}

variable "routes"{
    description = <<-EOT
    Map of "METHOD /path" to its handler configuration. The key is the API
Gateway route key. `handler` must match a name in services/handlers.json.
EOT
type = map(object({
handler= string

authorization= optional(string, "NONE")

memory_mb= optional(number, 512)
timeout_seconds= optional(number, 10)
env=optional(map(string), {})

policy_json=optional(string)


reserved_concurrency =optional(number,-1)

}))
validation {
condition = alltrue([
for cfg in values(var.routes) : contains(["NONE", "JWT"], cfg.authorization)
])
error_message = "Each route's authorization must be NONE or JWT."
}
validation {
    condition = alltrue([
        for key in keys(var.routes) : can(regex("^(GET|POST|PATCH|PUT|DELETE) /", key))
    ])
    error_message = "Route keys must look like \"GET /health\"."
}

}
}