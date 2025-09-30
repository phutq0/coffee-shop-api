variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "immutability" {
  description = "Image tag immutability (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = false
}

variable "lifecycle_keep_last" {
  description = "Lifecycle policy: keep last N tagged images"
  type        = number
  default     = 20
}

variable "kms_key_arn" {
  description = "KMS key ARN for ECR encryption (optional)"
  type        = string
  default     = null
}

variable "repository_policy_json" {
  description = "Optional repository policy JSON (for cross-account, etc.)"
  type        = string
  default     = null
}
