// Agencies Table
resource "aws_dynamodb_table" "agencies" {
  name         = "${var.name_prefix}-agencies"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "agency_id"

  attribute {
    name = "agency_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection
  tags = {
    "Component" = "data"
  }
}

// Users Table
resource "aws_dynamodb_table" "users" {
  name         = "${var.name_prefix}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  attribute {
    name = "agency_id"
    type = "S"
  }
  attribute {
    name = "user_id"
    type = "S"
  }
  global_secondary_index {
    name = "by_agencies"
    key_schema {
      attribute_name = "agency_id"
      key_type       = "HASH"
    }
    key_schema {
      attribute_name = "user_id"
      key_type       = "RANGE"
    }
    projection_type = "ALL"
  }
  server_side_encryption {
    enabled = true
  }
  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  deletion_protection_enabled = var.deletion_protection
  tags                        = { Component = "data" }

}