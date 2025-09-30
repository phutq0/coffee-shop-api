variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID for DB security group"
  type        = string
}

variable "subnet_ids" {
  description = "Database subnet IDs (two AZs minimum)"
  type        = list(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "coffeeshop"
}

variable "password" {
  description = "Master password (optional, random if null)"
  type        = string
  default     = null
  sensitive   = true
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15"
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max autoscaling storage in GB"
  type        = number
  default     = 100
}

variable "kms_key_id" {
  description = "Optional KMS key ID for encryption"
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Automated backup retention (days)"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval (seconds)"
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "ingress_sg_ids" {
  description = "Security Group IDs allowed to connect (e.g., ECS SG)"
  type        = list(string)
  default     = []
}

variable "create_read_replica" {
  description = "Create a read replica"
  type        = bool
  default     = false
}

variable "parameter_overrides" {
  description = "Map of DB parameter overrides (parameter_name => value)"
  type        = map(string)
  default     = {}
}

variable "enable_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for key metrics"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = null
}

variable "store_connection_secret" {
  description = "Store connection details in Secrets Manager"
  type        = bool
  default     = true
}

variable "connection_secret_name" {
  description = "Secrets Manager name for connection string"
  type        = string
  default     = null
}
