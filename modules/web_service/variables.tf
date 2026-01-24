variable "name_prefix" {
  description = "Prefix for naming resources."
  type        = string
  default     = "myapp"
}

variable "region" {
  type = string
}

variable "ssm_and_secret_prefix" {
  type    = string
  default = "lab"
}

variable "db_secret_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "publish_custom_metric" {
  type    = bool
  default = false
}

variable "enable_alb_access_logs" {
  type    = bool
  default = false
}

variable "alb_log_prefix" {
  type    = string
  default = "alb-logs"
}

variable "enabled_alb_tls" {
  type    = bool
  default = false
}

variable "vpc_endpoint_services" {
  type = list(string)
}

variable "alb_subnets" {
  type = list(string)
}


variable "logs_bucket_id" {
  type    = string
  default = null
}

variable "secret_header_name" {
  type = string
}

variable "secret_header_value" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "instance_subnet" {
  type = string
}

variable "restrict_alb_access_with_header" {
  type        = bool
  default     = false
  description = "If this is set to true then an http listener will be created that will require your custom header is used. A \"fallback\" listener will also be created to send requests that don't have the header to a 403 page"
}

variable "vpc_endpoint_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Subnets to put vpc endpoints in. These should be private subnets."
}

variable "restrict_alb_to_cloudfront" {
  type    = bool
  default = false
}
