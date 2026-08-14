resource "aws_cognito_user_pool_client" "web" {
  name         = "${var.name_prefix}-web"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  id_token_validity       = 60
  access_token_validity   = 60
  refresh_token_validity  = 30
  enable_token_revocation = "true"
  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }
  prevent_user_existence_errors = "ENABLED"
  write_attributes = [
    "email",
    "name"
  ]

  read_attributes = [
    "email",
    "email_verified",
    "name",
    "custom:agency_id",
    "custom:role",
    "custom:onboarding_stage"
  ]

}
