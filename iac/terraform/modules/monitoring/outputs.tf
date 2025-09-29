output "sns_topic_critical_arn" {
  value = aws_sns_topic.critical.arn
}

output "sns_topic_warning_arn" {
  value = aws_sns_topic.warning.arn
}

output "sns_topic_info_arn" {
  value = aws_sns_topic.info.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.this.dashboard_name
}
