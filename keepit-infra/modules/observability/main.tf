# Lambda error alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.name_prefix}-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  dimensions = {
    FunctionName = regex("arn:aws:lambda:[^:]+:[0-9]+:function:(.+)", var.api_lambda_arn)[0]
  }
  treat_missing_data = "notBreaching"
}

# (Example) DynamoDB throttles alarm (any table)
resource "aws_cloudwatch_metric_alarm" "dynamo_throttles" {
  alarm_name          = "${var.name_prefix}-dynamo-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  # No dimensions => all tables in account/region
}
