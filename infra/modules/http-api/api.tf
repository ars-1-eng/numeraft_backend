
// Create API - Defining the HTTP API
//  What service exists?

resource "aws_apigatewayv2_api" "http"{
    name="${var.name_prefix}-http"
    protocol_type = "HTTP"
    description = "Numeraft API for ${var.name_prefix}"
    cors_configuration {
      allow_origins = var.cors_origins
      max_age = 3600
      allow_methods = ["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"]
allow_headers = ["authorization", "content-type", "x-request-id"]
    }

}


// Create cloudwatch log - Receives API access logs
// Where are incoming-request records stored?

resource "aws_cloudwatch_log_group" "access" {
  name="/aws/apigw/${var.name_prefix}-http"
  retention_in_days = var.log_retention_days
}


// API Stage- Publishesh API and controls throttling/logging
//  How and where is it exposed?

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.http.id
  name   = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = var.throttle_burst
    throttling_rate_limit = var.throttle_rate
    detailed_metrics_enabled = var.detailed_metrics

  }

  access_log_settings { 
    destination_arn = aws_cloudwatch_log_group.access.arn
    format = jsonencode({
        requestId= "$context.requestId"
        sourceIp= "$context.identity.sourceIp"

        method= "$context.httpMethod"

        routeKey= "$context.routeKey"

        status= "$context.status"

        responseLatency = "$context.responseLatency"
        integrationError = "$context.integrationErrorMessage"
        userAgent= "$context.identity.userAgent"

        authorizerError = "$context.authorizer.error"
    })
    

}
}