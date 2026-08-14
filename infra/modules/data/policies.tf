# What GET /me needs: read the agency, read the user mapping.
data "aws_iam_policy_document" "read_identity" {
  statement {
    sid     = "ReadAgencyAndUser"
    effect  = "Allow"
    actions = ["dynamodb:GetItem", "dynamodb:Query"]
    resources = [
      aws_dynamodb_table.agencies.arn,
      aws_dynamodb_table.users.arn,
      "${aws_dynamodb_table.users.arn}/index/*",
    ]
  }
}
# What the post-confirmation trigger and POST /me/bootstrap need: create
# the pair of records, idempotently. No DeleteItem: nothing in this system
# has a reason to delete an agency, and omitting it means a bug cannot.
data "aws_iam_policy_document" "provision_identity" {
  statement {
    sid    = "CreateAgencyAndUser"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.agencies.arn,
      aws_dynamodb_table.users.arn,
      "${aws_dynamodb_table.users.arn}/index/*",
    ]
  }
}
