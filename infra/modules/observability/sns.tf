# TOPIC → SUBSCRIBER → PUBLISH POLICY → ATTACH POLICY



// Define the notification Channel


resource "aws_sns_topic" "alerts"{
    name = "${var.name_prefix}-alerts"
    tags = {
      Component ="observability" 
    }
}


//   Add the Recipient

resource "aws_sns_topic_subscription" "email"{
    topic_arn = aws_sns_topic.alerts.arn
    endpoint = var.alert_email
    protocol = "email"
}


// Publish Policy

data "aws_iam_policy_document" "alerts"{
    statement {
      sid = "AllowCloudWatchAlarms"
      effect = "Allow"
      actions = [ "sns:Publish" ]
      principals {
        type = "Service"
identifiers = ["cloudwatch.amazonaws.com", "budgets.amazonaws.com"]
      }
      resources = [aws_sns_topic.alerts.arn]

    }
}


// Attach Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = data.aws_iam_policy_document.alerts.json
}
