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

# do I need a bucket policy for flow logs

# VPC
module "vpc" {
  source = "../vpc"

  providers = {
    aws = aws
  }
  name_prefix            = var.name_prefix
  region                 = var.region
  vpc_cidr               = var.vpc_cidr
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
  availability_zones     = var.availability_zones
  include_nat_gateway    = var.include_nat_gateway
  vpc_flow_logs_bucket   = module.s3.s3_bucket_arn
  cloudtrail_logs_bucket = module.s3.s3_bucket_id

  depends_on = [module.s3]
}

# RDS
module "rds" {
  source = "../rds"

  providers = {
    aws = aws
  }
  name_prefix       = var.name_prefix
  db_engine         = var.db_engine
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  rds_db_subnet_ids = module.vpc.private_subnet_ids
  vpc_id            = module.vpc.vpc_id
  logs_bucket       = module.s3.s3_bucket_arn
  allowed_sg_ids    = [module.web_service.web_instance_sg_id]
}

resource "aws_vpc_security_group_ingress_rule" "allow_peer_cidr_inbound_rule" {
  security_group_id = module.rds.rds_security_group_id
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = var.tgw_peer_cidr
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
  db_secret_name                  = module.rds.db_secret_name
  vpc_id                          = module.vpc.vpc_id
  ami_id                          = var.ami_id
  instance_type                   = var.instance_type
  publish_custom_metric           = false
  enable_alb_access_logs          = var.enable_alb_access_logs
  alb_log_prefix                  = local.alb_log_prefix
  enabled_alb_tls                 = false
  vpc_endpoint_services           = var.vpc_endpoint_services
  alb_subnets                     = module.vpc.public_subnet_ids
  logs_bucket_id                  = module.s3.s3_bucket_id
  secret_header_name              = var.secret_header_name
  secret_header_value             = var.secret_header_value
  instance_subnet                 = module.vpc.private_subnet_ids[0]
  restrict_alb_access_with_header = var.restrict_alb_access_with_header
  vpc_endpoint_subnet_ids         = []
  restrict_alb_to_cloudfront      = var.restrict_alb_to_cloudfront
  certificate_arn                 = module.acm.certificate_arn
}

resource "aws_route53_record" "alb_app_alias" {
  zone_id = module.acm.primary_domain_zone_id
  name    = "tokyo"
  type    = "A"

  alias {
    name                   = module.web_service.alb_dns_name
    zone_id                = module.web_service.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "tokyo_latency_record" {
  zone_id        = module.acm.primary_domain_zone_id
  name           = ""
  type           = "A"
  set_identifier = "tokyo"
  latency_routing_policy {
    region = var.region
  }
  alias {
    name                   = module.web_service.alb_dns_name
    zone_id                = module.web_service.alb_zone_id
    evaluate_target_health = true
  }
}

module "tgw" {
  source = "../tgw"

  providers = {
    aws = aws
  }

  gateway_description       = "Tokyo TGW (Hub)"
  name_prefix               = var.name_prefix
  vpc_id                    = module.vpc.vpc_id
  subnets                   = var.tgw_subnets
  availability_zones        = var.availability_zones
  peer_region               = var.tgw_peer_region
  create_peering_attachment = true
  peer_transit_gateway_id   = var.tgw_peer_tgw_id
  peer_attachment_name      = "tokyo-to-${var.tgw_peer_region}-peering-attachment"
  peer_cidr_block           = var.tgw_peer_cidr
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
