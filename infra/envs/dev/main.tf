//CALCULATE → CONFIGURE API → DEFINE ROUTES → EXPORT RESULTS → MONITOR RESULTS


locals{
    name="${var.app_name}-${var.environment}"
    services_dist="${path.root}/../../../services/dist"
    common_env={
        APP_NAME=var.app_name
        ENVIRONMENT=var.environment
    }
}



module "api" {
  source = "../../modules/http-api"
  name_prefix = local.name
  account_id = var.aws_account_id
  services_dist_dir = local.services_dist
  cors_origins = var.cors_origins
  throttle_burst = var.api_throttle_burst
  throttle_rate = var.api_throttle_rate
  log_retention_days = var.log_retention_days
  log_level = var.log_level
  detailed_metrics = true
  jwt_issuer = null
  jwt_audiences = []
  routes = {
    "GET /health" = {
      handler = "health"
      authorization = "NONE"
      memory_mb = 256
      env = local.common_env
    }
  }
}
module "observability" {
  source             = "../../modules/observability"
  name_prefix        = local.name
  alert_email        = var.alert_email
  api_id             = module.api.api_id
  function_names     = module.api.function_names
  monthly_budget_usd = var.monthly_budget_usd
}