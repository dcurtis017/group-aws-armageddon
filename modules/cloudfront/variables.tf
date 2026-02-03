variable "name_prefix" {
  type = string
}

variable "secret_header_name" {
  type = string
}

variable "secret_header_value" {
  type = string
}

variable "root_domain_name" {
  type = string
}

variable "app_subdomain" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "origin_dns_name" {
  type = string
}

variable "waf_arn" {
  type    = string
  default = null
}

variable "log_group_name" {
  type    = string
  default = "/aws/cloudfront/lab-distribution-logs"
}
