variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for ALB"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "target_port" {
  description = "Target port that ECS container listens on"
  type        = number
  default     = 8080
}

variable "health_check" {
  description = "Target group health check settings"
  type = object({
    path                = string
    interval            = number
    timeout             = number
    healthy_threshold   = number
    unhealthy_threshold = number
    matcher             = string
  })
  default = {
    path                = "/api/actuator/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

variable "stickiness_enabled" {
  description = "Enable target group stickiness"
  type        = bool
  default     = true
}

variable "stickiness_duration_seconds" {
  description = "Stickiness cookie duration"
  type        = number
  default     = 86400
}

variable "deregistration_delay" {
  description = "Target group deregistration delay in seconds"
  type        = number
  default     = 60
}

variable "enable_cross_zone_lb" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "create_https_listener" {
  description = "Create HTTPS listener"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM Certificate ARN for HTTPS"
  type        = string
  default     = null
}

variable "enable_http_redirect" {
  description = "Redirect HTTP to HTTPS"
  type        = bool
  default     = true
}

variable "logs" {
  description = "ALB access logs configuration"
  type = object({
    enabled        = bool
    create_bucket  = bool
    bucket_name    = string
    prefix         = string
    lifecycle_days = number
  })
  default = {
    enabled        = false
    create_bucket  = false
    bucket_name    = null
    prefix         = "alb"
    lifecycle_days = 30
  }
}

variable "waf_web_acl_arn" {
  description = "Optional WAF WebACL ARN"
  type        = string
  default     = null
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = null
}
