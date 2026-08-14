
resource "aws_apigatewayv2_authorizer" "jwt" {
  count            = var.jwt_issuer == null ? 0 : 1
  api_id           = aws_apigatewayv2_api.http.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.name_prefix}-jwt"

  jwt_configuration {
    audience = var.jwt_audiences
    issuer   = var.jwt_issuer
  }

}