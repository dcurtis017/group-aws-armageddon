# Common
locals {
  ssm_and_secret_prefix = "lab"
  alb_log_prefix        = "alb-logs"
  secret_header_name    = "ChewyLives"
  app_subdomain         = "app"
  lab_prefix            = "armageddon-lab3"
}

resource "random_string" "header_value" {
  length  = 8
  special = false
  upper   = false
}

# ACM -- this will be in us-east-1 and for cloudfront
# Japan and Brazil use their own region specific certs
module "acm" {
  source           = "../modules/acm"
  root_domain_name = var.root_domain_name
}
# Tokyo

module "tokyo" {
  source = "../modules/tokyo"
  providers = {
    aws = aws.tokyo
  }
  name_prefix = var.tokyo_prefix

  region              = var.tokyo_region
  vpc_cidr            = var.tokyo_vpc_cidr
  public_subnets      = var.tokyo_public_subnets
  private_subnets     = var.tokyo_private_subnets
  availability_zones  = var.tokyo_availability_zones
  include_nat_gateway = true

  log_bucket_name   = var.tokyo_log_bucket_name
  db_engine         = var.db_engine
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password

  root_domain_name = var.root_domain_name

  sns_email_endpoint    = var.sns_email_endpoint
  vpc_endpoint_services = var.vpc_endpoint_services

  ami_id        = var.tokyo_ami
  instance_type = var.instance_type

  ssm_and_secret_prefix = local.ssm_and_secret_prefix
  secret_header_name    = local.secret_header_name
  secret_header_value   = random_string.header_value.result

  tgw_peer_cidr          = var.saopaulo_vpc_cidr
  tgw_subnets            = var.tokyo_tgw_subnets
  tgw_availability_zones = var.tokyo_tgw_availability_zones
  tgw_peer_region        = var.saopaulo_region
  tgw_peer_tgw_id        = module.saopaulo.tgw_id

  restrict_alb_access_with_header = false
  restrict_alb_to_cloudfront      = true
  enable_alb_access_logs          = true
}

module "saopaulo" {
  source = "../modules/saopaulo"
  providers = {
    aws = aws.saopaulo
  }
  name_prefix = var.saopaulo_prefix

  region              = var.saopaulo_region
  vpc_cidr            = var.saopaulo_vpc_cidr
  public_subnets      = var.saopaulo_public_subnets
  private_subnets     = var.saopaulo_private_subnets
  availability_zones  = var.saopaulo_availability_zones
  include_nat_gateway = true

  log_bucket_name = var.saopaulo_log_bucket_name

  root_domain_name = var.root_domain_name

  sns_email_endpoint    = var.sns_email_endpoint
  vpc_endpoint_services = var.vpc_endpoint_services

  ami_id        = var.saopaulo_ami
  instance_type = var.instance_type

  ssm_and_secret_prefix = local.ssm_and_secret_prefix
  secret_header_name    = local.secret_header_name
  secret_header_value   = random_string.header_value.result
  db_secret_name        = module.tokyo.db_secret_name

  tgw_subnets               = var.saopaulo_tgw_subnets
  tgw_availability_zones    = var.saopaulo_tgw_availability_zones
  tgw_peer_cidr             = var.tokyo_vpc_cidr
  tgw_peering_attachment_id = module.tokyo.tgw_peering_attachment_id

  restrict_alb_access_with_header = false
  restrict_alb_to_cloudfront      = true
  enable_alb_access_logs          = true
}

data "aws_secretsmanager_secret_version" "tokyo_db_secret" {
  provider   = aws.tokyo
  secret_id  = module.tokyo.db_secret_id
  depends_on = [module.tokyo]
}

resource "aws_secretsmanager_secret" "tokyo_db_secret_saopaulo_replica" {
  provider                = aws.saopaulo
  name                    = module.tokyo.db_secret_name
  recovery_window_in_days = 0
  depends_on              = [module.tokyo]
}

resource "aws_secretsmanager_secret_version" "tokyo_db_secret_saopaulo_replica_version" {
  provider      = aws.saopaulo
  secret_id     = aws_secretsmanager_secret.tokyo_db_secret_saopaulo_replica.id
  secret_string = data.aws_secretsmanager_secret_version.tokyo_db_secret.secret_string
  depends_on    = [module.tokyo]
}

# WAF

module "waf" {
  source = "../modules/waf"

  name_prefix                     = local.lab_prefix
  enable_waf                      = var.enable_waf
  enable_waf_logging              = var.enable_waf_logging
  associate_waf_with_resource_arn = null
  waf_scope                       = "CLOUDFRONT"
  include_waf_acl_association     = false
}
# cloudfront -- do this here since the module isn't generic enough
# latency route is defined in the tokyo and sao paulo modules

module "cf" {
  source              = "../modules/cloudfront"
  name_prefix         = local.lab_prefix
  secret_header_name  = local.secret_header_name
  secret_header_value = random_string.header_value.result
  acm_certificate_arn = module.acm.certificate_arn
  origin_dns_name     = var.root_domain_name
  waf_arn             = module.waf.waf_acl_arn
  aliases             = [var.root_domain_name]
}
