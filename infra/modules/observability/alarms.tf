resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name        = "${var.name_prefix}-api-5xx"
  alarm_description = "The API is returning server errors."

  namespace   = "AWS/ApiGateway"
  metric_name = "5xx"

  dimensions = {
    ApiId = var.api_id
  }

  statistic          = "Sum"
  period             = 300
  evaluation_periods = 1

  threshold           = var.api_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # No traffic means no metric data. Treat it as healthy.
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name        = "${var.name_prefix}-api-latency-p99"
  alarm_description = "API p99 latency is degrading."

  namespace   = "AWS/ApiGateway"
  metric_name = "Latency"

  dimensions = {
    ApiId = var.api_id
  }

  extended_statistic = "p99"
  period             = 300
  evaluation_periods = 2

  threshold           = var.api_latency_p99_ms
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = toset(var.function_names)

  alarm_name        = "${each.value}-errors"
  alarm_description = "Unhandled exception in ${each.value}. Check its log group."

  namespace   = "AWS/Lambda"
  metric_name = "Errors"

  dimensions = {
    FunctionName = each.value
  }

  statistic          = "Sum"
  period             = 300
  evaluation_periods = 1

  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  for_each = toset(var.function_names)

  alarm_name        = "${each.value}-throttles"
  alarm_description = "${each.value} hit a concurrency limit. Requests were rejected."

  namespace   = "AWS/Lambda"
  metric_name = "Throttles"

  dimensions = {
    FunctionName = each.value
  }

  statistic          = "Sum"
  period             = 300
  evaluation_periods = 1

  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}