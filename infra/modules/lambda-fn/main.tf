data "archive_file" "bundle" {
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.name}.zip"
  type        = "zip"
}



resource "aws_cloudwatch_log_group" "fn" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "fn" {
  name = "${var.name}-exec"
  tags = var.tags

  assume_role_policy = jsonencode({
    Effect    = "Allow"
    Action    = "sts:AssumeRole"
    Principle = { Service = "lambda:amazonaws.com" }
    Conditions = {
      StringEquals = {
        "aws:SourceAccount" = var.account_id
      }
    }
  })

}

data "aws_iam_policy_document" "logs" {
  statement {
    sid = "WriteOwnLogs"
    actions = ["logs:CreateLogStream",
    "logs:PutLogEvents"]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.fn.arn}:*"]
  }

  dynamic "statement" {
    for_each = var.tracing ? [1] : []
    content {
      sid       = "XRay"
      effect    = "Allow"
      actions   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
      resources = ["*"]

    }
  }
}


resource "aws_iam_role_policy" "logs" {
  name   = "logs"
  role   = aws.iam_role.fn.id
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy" "extra" {
  count  = var.extra_policy_json == null ? 0 : 1
  name   = "resources"
  role   = aws_iam_role.fn.id
  policy = var.extra_policy_json
}


// lambda


resource "aws_lambda_function" "fn" {
  function_name = var.name
  role          = aws_iam_role.fn.arn

  handler = var.handler

  runtime = var.runtime

  architectures = ["arm64"]
  filename      = data.archive_file.bundle.output_path
  # Without a content hash, changing your TypeScript produces NO Terraform
  # diff and apply silently deploys nothing. If your provider version
  # rejects this argument, rename it to source_code_hash.
  code_sha256 = data.archive_file.bundle.output_base64sha256
  memory_size = var.memory_mb

  timeout = var.timeout_seconds

  reserved_concurrent_executions = var.reserved_concurrency
  environment {
    variables = merge(
      {
        LOG_LEVEL = var.log_level

        NODE_OPTIONS = "--enable-source-maps"

        POWERTOOLS_SERVICE_NAME = var.name
        POWERTOOLS_LOG_LEVEL    = var.log_level

      },
      var.environment_variables
    )
  }
  logging_config {
    log_format            = "JSON"
    application_log_level = var.log_level
    system_log_level      = "WARN"

    log_group = aws_cloudwatch_log_group.fn.name

  }
  tracing_config {
    mode = var.tracing ? "Active" : "PassThrough"
  }
  tags = var.tags
  depends_on = [
    aws_cloudwatch_log_group.fn,
    aws_iam_role_policy.logs,
  ]
}
