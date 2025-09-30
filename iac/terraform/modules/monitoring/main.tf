# SNS topics
resource "aws_sns_topic" "critical" {
  name = "${var.name}-critical"
  tags = var.tags
}

resource "aws_sns_topic" "warning" {
  name = "${var.name}-warning"
  tags = var.tags
}

resource "aws_sns_topic" "info" {
  name = "${var.name}-info"
  tags = var.tags
}

# Subscriptions (email)
resource "aws_sns_topic_subscription" "critical_email" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = each.value
}

# Dashboard
locals {
  widgets = compact([
    var.ecs_cluster_name == null ? null : {
      type = "metric", width = 12, height = 6, properties = {
        title = "ECS CPU/Memory",
        metrics = [
          ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, { "stat" : "Average" }],
          [".", "MemoryUtilization", ".", ".", { "stat" : "Average" }]
        ],
        period = 60, region = var.region, stacked = false
      }
    },
    var.alb_arn_suffix == null || var.tg_arn_suffix == null ? null : {
      type = "metric", width = 12, height = 6, properties = {
        title = "ALB 5XX & Target RT",
        metrics = [
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { "stat" : "Sum" }],
          [".", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.tg_arn_suffix, { "stat" : "Average" }]
        ],
        period = 60, region = var.region
      }
    },
    var.rds_identifier == null ? null : {
      type = "metric", width = 12, height = 6, properties = {
        title = "RDS CPU/Connections",
        metrics = [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_identifier, { "stat" : "Average" }],
          [".", "DatabaseConnections", ".", ".", { "stat" : "Average" }]
        ],
        period = 60, region = var.region
      }
    }
  ])
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-dashboard"
  dashboard_body = jsonencode({ widgets = local.widgets })
}

# Log metric filters and alarms for errors
resource "aws_cloudwatch_log_metric_filter" "errors" {
  for_each       = toset(var.app_log_group_names)
  name           = "${var.name}-errors-${replace(each.value, "/", "-")}"
  log_group_name = each.value
  pattern        = var.error_filter_pattern
  metric_transformation {
    name      = "${var.name}-error-count"
    namespace = "App/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_errors" {
  for_each            = toset(var.app_log_group_names)
  alarm_name          = "${var.name}-log-errors-${replace(each.value, "/", "-")}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.name}-error-count"
  namespace           = "App/Logs"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alarm_thresholds.log_error_rate_high
  alarm_description   = "High error rate in application logs"
  alarm_actions       = [aws_sns_topic.critical.arn]
}

# Optional cost alarm (billing metrics only in us-east-1)
resource "aws_cloudwatch_metric_alarm" "cost" {
  count               = var.enable_cost_alarms ? 1 : 0
  alarm_name          = "${var.name}-monthly-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = var.monthly_cost_threshold
  alarm_description   = "Monthly estimated cost exceeded"
  dimensions          = { Currency = "USD" }
  alarm_actions       = [aws_sns_topic.warning.arn]
}

# EventBridge rule placeholder (extend as needed)
resource "aws_cloudwatch_event_rule" "placeholder" {
  name                = "${var.name}-events"
  description         = "Placeholder EventBridge rule for automation"
  schedule_expression = "rate(1 day)"
}
