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

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "List of CIDRs for database subnets"
  type        = list(string)
}

variable "enable_nat_per_az" {
  description = "Create one NAT Gateway per AZ if true; else single NAT"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch"
  type        = bool
  default     = true
}

variable "vpc_endpoints" {
  description = "Enable interface/gateway endpoints"
  type = object({
    s3  = bool
    ecr = bool
  })
  default = {
    s3  = true
    ecr = true
  }
}

variable "enable_nacls" {
  description = "Manage Network ACLs for public/private/db subnets"
  type        = bool
  default     = true
}
