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
  description = "VPC ID for security groups"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR for endpoint SG rules"
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to access ALB on 80/443"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_http_port" {
  description = "ALB HTTP port"
  type        = number
  default     = 80
}

variable "alb_https_port" {
  description = "ALB HTTPS port"
  type        = number
  default     = 443
}

variable "app_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "create_kms" {
  description = "Whether to create a KMS key for encryption"
  type        = bool
  default     = true
}

variable "create_secrets" {
  description = "Whether to create Secrets Manager secrets"
  type        = bool
  default     = true
}

variable "db_secret_name" {
  description = "Secrets Manager name for DB credentials"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Optional DB username for secret payload"
  type        = string
  default     = null
}

variable "db_password" {
  description = "Optional DB password for secret payload; random if null"
  type        = string
  default     = null
  sensitive   = true
}

variable "jwt_secret_name" {
  description = "Secrets Manager name for JWT secret"
  type        = string
  default     = null
}

variable "jwt_secret_value" {
  description = "Optional JWT secret value; random if null"
  type        = string
  default     = null
  sensitive   = true
}

variable "ssm_params" {
  description = "Map of SSM parameter key->value for non-sensitive config"
  type        = map(string)
  default     = {}
}

variable "enable_vpce_sg" {
  description = "Create SG for VPC interface endpoints"
  type        = bool
  default     = true
}

variable "alb_logs_bucket_arn" {
  description = "Optional S3 bucket ARN for ALB access logs policy attachment"
  type        = string
  default     = null
}

variable "alb_logs_bucket_policy_json" {
  description = "Optional bucket policy JSON to allow ALB log delivery"
  type        = string
  default     = null
}
