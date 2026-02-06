variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "include_nat_gateway" {
  type = bool
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

variable "log_bucket_name" {
  type = string
}

variable "ssm_and_secret_prefix" {
  type = string
}

variable "secret_header_name" {
  type = string
}

variable "secret_header_value" {
  type = string
}

variable "tgw_subnets" {
  type = list(string)
}

variable "tgw_availability_zones" {
  type = list(string)
}

variable "tgw_peer_region" {
  type = string
}

variable "tgw_peer_tgw_id" {
  type = string
}

variable "tgw_peer_account_id" {
  type    = string
  default = null
}

variable "tgw_peer_cidr" {
  type = string
}
