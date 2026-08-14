resource "aws_cognito_user_pool" "main" {
  name = "${var.name_prefix}-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    require_uppercase                = true
    temporary_password_validity_days = 3
  }

  mfa_configuration = var.mfa_configuration

  software_token_mfa_configuration {
    enabled = var.mfa_configuration != "OFF"
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = !var.allow_self_signup

  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your Numeraft verification code"

    email_message = "Your Numeraft code is {####}. It expires in 24 hours."

  }

  schema {
    name                     = "agency_id"
    mutable                  = true
    attribute_data_type      = "String"
    developer_only_attribute = false

    string_attribute_constraints {
      max_length = 64
      min_length = 1
    }
  }
  schema {
    name                = "role"
    mutable             = true
    attribute_data_type = "String"

    string_attribute_constraints {
      max_length = 32
      min_length = 1
    }
  }
  schema {
    name                = "onboarding_stage"
    mutable             = true
    attribute_data_type = "String"


    string_attribute_constraints {
      max_length = 32
      min_length = 0
    }
  }

  lambda_config {

    post_confirmation = module.post_confirmation.arn
  }

  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"

  lifecycle {
    ignore_changes = [schema]
  }

  tags = {
    Component = "identity"
  }
}