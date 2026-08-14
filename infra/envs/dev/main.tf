//CALCULATE → CONFIGURE API → DEFINE ROUTES → EXPORT RESULTS → MONITOR RESULTS


locals {
  name          = "${var.app_name}-${var.environment}"
  services_dist = "${path.root}/../../../services/dist"
  is_prod       = var.environment == "prod"

  common_env = {
    APP_NAME    = var.app_name
    ENVIRONMENT = var.environment
  }
}

module "data" {
  source                 = "../../modules/data"
  name_prefix            = local.name
  point_in_time_recovery = local.is_prod
  deletion_protection    = local.is_prod
}


module "identity" {
  source                         = "../../modules/identity"
  account_id                     = var.aws_account_id
  aws-region                     = var.aws_region
  name_prefix                    = local.name
  provision_identity_policy_json = module.data.provision_identity_policy_json
  agencies_table_name            = module.data.agencies_table_name
  users_table_name               = module.data.users_table_name
  services_dist_dir              = local.services_dist
  log_level                      = var.log_level
  log_retention_days             = var.log_retention_days
  deletion_protection            = local.is_prod
  allow_self_signup              = var.allow_self_signup
  mfa_configuration              = var.mfa_configuration

}

module "api" {
  source             = "../../modules/http-api"
  name_prefix        = local.name
  account_id         = var.aws_account_id
  services_dist_dir  = local.services_dist
  cors_origins       = var.cors_origins
  throttle_burst     = var.api_throttle_burst
  throttle_rate      = var.api_throttle_rate
  log_retention_days = var.log_retention_days
  log_level          = var.log_level
  detailed_metrics   = !local.is_prod
  jwt_issuer         = module.identity.jwt_issuer
  jwt_audiences      = [module.identity.user_pool_client_id]
  common_env         = local.common_env
  routes = {
    "GET /health" = {
      handler       = "health"
      authorization = "NONE"
      memory_mb     = 256
    }

    "GET /me" = {
      handler       = "me"
      authorization = "JWT"
      memory_mb     = 512
    }

    "POST /me/bootstrap" = {
      handler              = "me_bootstrap"
      authorization        = "JWT"
      memory_mb            = 512
      reserved_concurrency = -1
    }
  }

  route_env = {
    "GET /me" = {
      AGENCIES_TABLE = module.data.agencies_table_name
      USERS_TABLE    = module.data.users_table_name

    }
    "POST /me/bootstrap" = {
      AGENCIES_TABLE = module.data.agencies_table_name
      USERS_TABLE    = module.data.users_table_name

      USER_POOL_ID = module.identity.user_pool_id
    }
  }
  route_policies = {
    "GET /me"            = module.data.read_identity_policy_json
    "POST /me/bootstrap" = module.identity.bootstrap_policy_json
  }

}
module "observability" {
  source             = "../../modules/observability"
  name_prefix        = local.name
  alert_email        = var.alert_email
  api_id             = module.api.api_id
  monthly_budget_usd = var.monthly_budget_usd

  function_names = concat(
    module.api.function_names,
    [module.identity.trigger_function_name]
  )
}
