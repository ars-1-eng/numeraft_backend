// Lambda → Integration → Route → Permission

module "fn" {
source= "../lambda-fn"
for_each = var.routes
name= "${var.name_prefix}-${each.value.handler}"

source_dir= "${var.services_dist_dir}/${each.value.handler}"

account_id= var.account_id

memory_mb= each.value.memory_mb

timeout_seconds= each.value.timeout_seconds

environment_variables = each.value.env
extra_policy_json= each.value.policy_json

reserved_concurrency = each.value.reserved_concurrency
log_retention_days= var.log_retention_days

log_level= var.log_level

tags = { Component = "api" }
}

resource "aws_apigatewayv2_integration" "fn" {
  for_each = var.routes

  api_id             = aws_apigatewayv2_api.http.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = module.fn[each.key].invoke_arn

  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource  "aws_apigatewayv2_route" "fn" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.key

  target = "integrations/${aws_apigatewayv2_integration.fn[each.key].id}"

  authorization_type = each.value.authorization

  authorizer_id = each.value.authorization == "JWT"? one(aws_apigatewayv2_authorizer.jwt[*].id): null

  lifecycle {
    precondition {
      condition = (
        each.value.authorization != "JWT" ||
        var.jwt_issuer != null
      )

      error_message = "Route ${each.key} requires JWT authorization but jwt_issuer is null. Pass the Cognito issuer from the identity module."
    }
  }
}
resource "aws_lambda_permission" "fn" {
  for_each = var.routes

  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.fn[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http.execution_arn}/*/${local.route_parts[each.key].method}${local.route_parts[each.key].path}"
}
