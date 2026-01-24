variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-west-2"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks."
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks."
  type        = list(string)
  default     = []
}

variable "include_nat_gateway" {
  description = "Whether to include a NAT Gateway in the VPC."
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for naming resources."
  type        = string
  default     = "myapp"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.32.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones list (match count with subnets). If you want to have multiple subnets in the same AZ, repeat the AZ in the list."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
