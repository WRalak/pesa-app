variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod"
  }
}
variable "region" {
  type    = string
  default = "af-south-1" # Cape Town — closest AWS region to East Africa
}
variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}
variable "azs" {
  type    = list(string)
  default = ["af-south-1a", "af-south-1b", "af-south-1c"]
}
variable "api_domain" { type = string }
variable "admin_domain" { type = string }
variable "acm_certificate_arn" { type = string }
variable "image_tag" { type = string }
variable "api_desired_count" {
  type    = number
  default = 2
}
variable "api_max_count" {
  type    = number
  default = 20
}
variable "worker_desired_count" {
  type    = number
  default = 2
}
variable "api_cpu" {
  type    = number
  default = 1024
}
variable "api_memory" {
  type    = number
  default = 2048
}
variable "redis_node_type" {
  type    = string
  default = "cache.t4g.medium"
}
variable "admin_allowed_cidrs" {
  description = "Corporate VPN / ZTNA egress ranges allowed to reach the internal admin console."
  type        = list(string)
}
variable "mongodb_uri_secret_arn" {
  description = "Secrets Manager ARN holding the MongoDB Atlas SRV URI (private endpoint)."
  type        = string
}
variable "alarm_sns_topic_arn" { type = string }
variable "email_from" {
  description = "Verified SES sender, e.g. no-reply@pesa.africa"
  type        = string
}
variable "ses_region" {
  description = "SES region (SES is not available in every region; eu-west-1 is closest with full SES support)."
  type        = string
  default     = "eu-west-1"
}
variable "daraja_callback_ips" {
  description = "Safaricom's published callback source IPs (from your Safaricom integration contact)."
  type        = list(string)
}
