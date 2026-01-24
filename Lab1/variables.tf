variable "region" {
  type = string
}

variable "default_tags" {
  type = map(string)
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "db_engine" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "sns_email_endpoint" {
  type = string
}

variable "vpc_endpoint_services" {
  type = list(string)
}

variable "root_domain_name" {
  type = string
}

variable "enable_waf" {
  type = bool
}

variable "enable_alb_access_logs" {
  type = bool
}

variable "enable_waf_logging" {
  type = bool
}

variable "alb_5xx_error_threshold" {
  type    = number
  default = 10
}

variable "alb_5xx_error_evaluation_periods" {
  type    = number
  default = 1
}

variable "alb_5xx_period_seconds" {
  type    = number
  default = 300
}

variable "alb_log_prefix" {
  type    = string
  default = "alb-logs"
}

variable "waf_log_prefix" {
  type    = string
  default = "waf-logs"
}
