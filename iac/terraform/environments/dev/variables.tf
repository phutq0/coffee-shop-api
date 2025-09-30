variable "name" {
  type    = string
  default = "coffee-shop"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "tags" {
  type = map(string)
  default = {
    "environment" = "dev"
    "managed-by"  = "terraform"
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.4.0/24", "10.0.5.0/24"]
}

variable "enable_nat_per_az" {
  type    = bool
  default = false
}

variable "enable_vpc_flow_logs" {
  type    = bool
  default = false
}

variable "alb_create_https" {
  type    = bool
  default = false
}

variable "alb_enable_http_redirect" {
  type    = bool
  default = true
}

variable "alb_certificate_arn" {
  type    = string
  default = null
}

variable "app_image" {
  type    = string
  default = "coffee-shop-api"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "ecs_cpu" {
  type    = number
  default = 512
}

variable "ecs_memory" {
  type    = number
  default = 1024
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "coffeeshop"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "notification_emails" {
  type    = list(string)
  default = []
}
