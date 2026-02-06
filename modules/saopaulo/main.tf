# Provider Info
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

locals {
  alb_log_prefix = "alb-logs"
}

# acm cert

module "acm" {
  providers = {
    aws = aws
  }
  source           = "../acm"
  root_domain_name = var.root_domain_name
}

# S3 Bucket for Logs
module "s3" {
  source = "../s3"

  providers = {
    aws = aws
  }
  name_prefix    = var.name_prefix
  alb_log_prefix = local.alb_log_prefix
}

# VPC
module "vpc" {
  source = "../vpc"

  providers = {
    aws = aws
  }
  name_prefix         = var.name_prefix
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  availability_zones  = var.availability_zones
  include_nat_gateway = var.include_nat_gateway
}

# Web Service
module "web_service" {
  source = "../web_service"
  providers = {
    aws = aws
  }
  name_prefix                     = var.name_prefix
  region                          = var.region
  ssm_and_secret_prefix           = var.ssm_and_secret_prefix
  db_secret_name                  = var.db_secret_name
  vpc_id                          = module.vpc.vpc_id
  ami_id                          = var.ami_id
  instance_type                   = var.instance_type
  publish_custom_metric           = false
  enable_alb_access_logs          = false
  alb_log_prefix                  = local.alb_log_prefix
  enabled_alb_tls                 = false
  vpc_endpoint_services           = var.vpc_endpoint_services
  alb_subnets                     = module.vpc.public_subnet_ids
  logs_bucket_id                  = module.s3.s3_bucket_id
  secret_header_name              = var.secret_header_name
  secret_header_value             = var.secret_header_value
  instance_subnet                 = module.vpc.private_subnet_ids[0]
  restrict_alb_access_with_header = false
  vpc_endpoint_subnet_ids         = []
  restrict_alb_to_cloudfront      = false
  certificate_arn                 = module.acm.certificate_arn
}

resource "aws_route53_record" "alb_app_alias" {
  zone_id = module.acm.primary_domain_zone_id
  name    = "saopaulo"
  type    = "A"

  alias {
    name                   = module.web_service.alb_dns_name
    zone_id                = module.web_service.alb_zone_id
    evaluate_target_health = true
  }
}

# Transit Gateway Routes
module "tgw" {
  source = "../tgw"

  providers = {
    aws = aws
  }

  gateway_description                = "Sao Paulo TGW (Spoke)"
  name_prefix                        = var.name_prefix
  vpc_id                             = module.vpc.vpc_id
  subnets                            = var.tgw_subnets
  availability_zones                 = var.tgw_availability_zones
  tgw_peering_attachment_id          = var.tgw_peering_attachment_id
  create_peering_attachment_acceptor = true
  peer_cidr_block                    = var.tgw_peer_cidr
}

resource "aws_route" "route_to_peer" {
  route_table_id         = module.tgw.tgw_route_table_id
  destination_cidr_block = var.tgw_peer_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

resource "aws_route" "route_private_rt_to_peer" {
  route_table_id         = module.vpc.private_route_table_id
  destination_cidr_block = var.tgw_peer_cidr
  transit_gateway_id     = module.tgw.tgw_id
}
