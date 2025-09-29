variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "db_subnet_cidrs" {
  type = list(string)
}

variable "enable_nat_per_az" {
  type = bool
}

variable "enable_vpc_flow_logs" {
  type = bool
}

variable "alb_create_https" {
  type    = bool
  default = true
}

variable "alb_enable_http_redirect" {
  type    = bool
  default = true
}

variable "alb_certificate_arn" {
  type = string
}

variable "app_image" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "ecs_cpu" {
  type    = number
  default = 1024
}

variable "ecs_memory" {
  type    = number
  default = 2048
}

variable "desired_count" {
  type    = number
  default = 3
}

variable "db_name" {
  type    = string
  default = "coffeeshop"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_multi_az" {
  type    = bool
  default = true
}

variable "notification_emails" {
  type    = list(string)
  default = []
}
