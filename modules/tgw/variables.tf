variable "gateway_description" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "peer_region" {
  type    = string
  default = null
}

variable "peer_account_id" {
  type        = string
  default     = null
  description = "Account ID for Peer. If no account is is provided, the account id for the provider will be used."
}

variable "peer_transit_gateway_id" {
  type        = string
  default     = null
  description = "If this is not null then an aws_ec2_transit_gateway_peering_attachment will be created."
}

variable "peer_attachment_name" {
  type    = string
  default = null
}

variable "tgw_peering_attachment_id" {
  type        = string
  default     = null
  description = "If this is not null then an aws_ec2_transit_gateway_peering_attachment_acceptor will be created."
}

variable "create_peering_attachment" {
  type    = bool
  default = false
}

variable "create_peering_attachment_acceptor" {
  type    = bool
  default = false
}

variable "peer_cidr_block" {
  type = string
}
