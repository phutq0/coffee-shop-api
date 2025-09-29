variable "name" {
  description = "Name prefix for monitoring resources"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "notification_emails" {
  description = "Email addresses to subscribe to SNS topics"
  type        = list(string)
  default     = []
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for dashboard widgets (optional)"
  type        = string
  default     = null
}

variable "ecs_service_name" {
  description = "ECS service name for dashboard widgets (optional)"
  type        = string
  default     = null
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for dashboard widgets (optional)"
  type        = string
  default     = null
}

variable "tg_arn_suffix" {
  description = "ALB Target Group ARN suffix for dashboard widgets (optional)"
  type        = string
  default     = null
}

variable "rds_identifier" {
  description = "RDS DB instance identifier for widgets/alarms (optional)"
  type        = string
  default     = null
}

variable "app_log_group_names" {
  description = "List of CloudWatch Log Group names to create metric filters and alarms on"
  type        = list(string)
  default     = []
}

variable "error_filter_pattern" {
  description = "Log filter pattern for errors"
  type        = string
  default     = "?ERROR ?Error ?Exception"
}

variable "alarm_thresholds" {
  description = "Thresholds for alarms"
  type = object({
    ecs_cpu_high         = number
    ecs_memory_high      = number
    alb_5xx_high         = number
    alb_target_rt_high   = number
    rds_cpu_high         = number
    rds_connections_high = number
    rds_free_storage_low = number
    log_error_rate_high  = number
  })
  default = {
    ecs_cpu_high         = 80
    ecs_memory_high      = 80
    alb_5xx_high         = 10
    alb_target_rt_high   = 1
    rds_cpu_high         = 80
    rds_connections_high = 100
    rds_free_storage_low = 2000000000
    log_error_rate_high  = 5
  }
}

variable "enable_cost_alarms" {
  description = "Enable AWS Billing cost alarm (requires us-east-1)"
  type        = bool
  default     = false
}

variable "monthly_cost_threshold" {
  description = "Monthly estimated cost alarm threshold in USD"
  type        = number
  default     = 50
}
