variable "name" { type = string }
variable "region" { type = string }

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "cluster_name" { type = string }
variable "enable_container_insights" {
  type    = bool
  default = true
}

variable "image" { type = string }
variable "container_port" {
  type    = number
  default = 8080
}
variable "cpu" {
  type    = number
  default = 512
}
variable "memory" {
  type    = number
  default = 1024
}
variable "task_env" {
  type = map(string)
  default = {
    "DB_USERNAME"    = "coffeeshop"
    "JWT_EXPIRATION" = "86400000"
  }
}
variable "task_secrets" {
  description = "Map of ENV_NAME => Secrets Manager ARN"
  type        = map(string)
  default     = {}
}

variable "healthcheck" {
  description = "Container healthcheck configuration"
  type = object({
    command     = list(string)
    interval    = number
    timeout     = number
    retries     = number
    startPeriod = number
  })
  default = {
    command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 10
  }
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "deployment_min_healthy_percent" {
  type    = number
  default = 50
}
variable "deployment_max_percent" {
  type    = number
  default = 200
}
variable "enable_circuit_breaker" {
  type    = bool
  default = true
}

variable "target_group_arn" {
  type    = string
  default = null
}

variable "service_discovery" {
  description = "Optional Cloud Map service discovery"
  type = object({
    namespace_id = string
    name         = string
  })
  default = null
}

variable "autoscaling" {
  description = "Target tracking autoscaling config"
  type = object({
    min_capacity       = number
    max_capacity       = number
    cpu_target         = number
    memory_target      = number
    scale_in_cooldown  = number
    scale_out_cooldown = number
  })
  default = {
    min_capacity       = 2
    max_capacity       = 4
    cpu_target         = 60
    memory_target      = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
