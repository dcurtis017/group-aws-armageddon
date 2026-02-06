variable "tokyo_log_bucket_name" {
  type = string
}

variable "tokyo_region" {
  type = string
}

variable "tokyo_vpc_cidr" {
  type = string
}

variable "tokyo_public_subnets" {
  type = list(string)
}

variable "tokyo_private_subnets" {
  type = list(string)
}

variable "tokyo_availability_zones" {
  type = list(string)
}

variable "tokyo_ami" {
  type    = string
  default = "ami-06cce67a5893f85f9"
}

variable "tokyo_tgw_subnets" {
  type = list(string)
}

variable "tokyo_tgw_availability_zones" {
  type = list(string)
}

variable "saopaulo_log_bucket_name" {
  type = string
}

variable "saopaulo_region" {
  type = string
}

variable "saopaulo_vpc_cidr" {
  type = string
}

variable "saopaulo_public_subnets" {
  type = list(string)
}

variable "saopaulo_private_subnets" {
  type = list(string)
}

variable "saopaulo_availability_zones" {
  type = list(string)
}

variable "saopaulo_ami" {
  type    = string
  default = "ami-0f85876b1aff99dde"
}

variable "saopaulo_tgw_subnets" {
  type = list(string)
}

variable "saopaulo_tgw_availability_zones" {
  type = list(string)
}

variable "acm_region" {
  type    = string
  default = "us-east-1"
}

variable "tokyo_prefix" {
  type    = string
  default = "shibuya"
}

variable "saopaulo_prefix" {
  type    = string
  default = "liberdade"
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
