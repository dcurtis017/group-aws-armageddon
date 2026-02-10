locals {
  ssm_and_secret_prefix = "lab"
  alb_log_prefix        = "alb-logs"
  secret_header_name    = "ChewyLives"
  app_subdomain         = "app"
}

data "aws_caller_identity" "current" {}

# Logs Bucket
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "${var.name_prefix}-logs-bucket-${random_string.bucket_suffix.result}"

  force_destroy = true
  tags = {
    Name = "${var.name_prefix}-logs-bucket-lab2"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_bucket_block_public_access" {
  bucket = aws_s3_bucket.logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "logs_bucket_ownership_controls" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs_bucket.arn,
          "${aws_s3_bucket.logs_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      # https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
      {
        Sid    = "AllowALBPutLogs"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com" # this is case sensitive for the word 'Service'
        }
        Action   = "s3:PutObject"
        Resource = ["${aws_s3_bucket.logs_bucket.arn}/${var.alb_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
      }
    ]
  })

}

# VPC
module "vpc" {
  source = "../modules/vpc"

  region              = var.region
  vpc_cidr            = "10.32.0.0/16"
  public_subnets      = ["10.32.1.0/24", "10.32.2.0/24"]
  private_subnets     = ["10.32.11.0/24", "10.32.12.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b"]
  include_nat_gateway = true
}

# ACM
module "acm" {
  source = "../modules/acm"

  root_domain_name = var.root_domain_name
}

# WAF
module "waf" {
  source = "../modules/waf"

  name_prefix                     = var.name_prefix
  enable_waf                      = var.enable_waf
  enable_waf_logging              = var.enable_waf_logging
  associate_waf_with_resource_arn = null
  waf_scope                       = "CLOUDFRONT"
  include_waf_acl_association     = false
}

# RDS 
module "rds" {
  source = "../modules/rds"

  ssm_and_secret_prefix      = local.ssm_and_secret_prefix
  logs_bucket                = aws_s3_bucket.logs_bucket.arn
  name_prefix                = var.name_prefix
  allowed_sg_ids             = [module.web_app.web_instance_sg_id]
  rds_db_subnet_ids          = module.vpc.private_subnet_ids
  db_engine                  = var.db_engine
  db_instance_class          = var.db_instance_class
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  db_is_publicly_accessible  = false
  skip_db_snapshot_on_delete = true
  vpc_id                     = module.vpc.vpc_id
}

# Web App

module "web_app" {
  source = "../modules/web_service"

  name_prefix                     = var.name_prefix
  region                          = var.region
  ssm_and_secret_prefix           = local.ssm_and_secret_prefix
  db_secret_name                  = module.rds.db_secret_name
  vpc_id                          = module.vpc.vpc_id
  ami_id                          = var.ami_id
  instance_type                   = var.instance_type
  publish_custom_metric           = true
  enable_alb_access_logs          = var.enable_alb_access_logs
  alb_log_prefix                  = local.alb_log_prefix
  enabled_alb_tls                 = true
  vpc_endpoint_services           = var.vpc_endpoint_services
  vpc_endpoint_subnet_ids         = [module.vpc.private_subnet_ids[0]]
  alb_subnets                     = module.vpc.public_subnet_ids
  logs_bucket_id                  = aws_s3_bucket.logs_bucket.id
  secret_header_name              = local.secret_header_name
  secret_header_value             = random_string.bucket_suffix.result
  certificate_arn                 = module.acm.certificate_arn
  instance_subnet                 = module.vpc.private_subnet_ids[0]
  restrict_alb_access_with_header = true
  restrict_alb_to_cloudfront      = true
}

# CloudFront
module "cf" {
  source              = "../modules/cloudfront"
  name_prefix         = var.name_prefix
  secret_header_name  = local.secret_header_name
  secret_header_value = random_string.bucket_suffix.result
  acm_certificate_arn = module.acm.certificate_arn
  origin_dns_name     = module.web_app.alb_dns_name
  waf_arn             = module.waf.waf_acl_arn
  aliases = [
    var.root_domain_name,
    "${local.app_subdomain}.${var.root_domain_name}"
  ]
}

# aliases for CF to use domain
resource "aws_route53_record" "alb_app_alias" {
  zone_id = module.acm.primary_domain_zone_id
  name    = local.app_subdomain
  type    = "A"

  alias {
    name                   = module.cf.cf_domain_name
    zone_id                = module.cf.cf_hosted_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "alb_alias" {
  zone_id = module.acm.primary_domain_zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = module.cf.cf_domain_name
    zone_id                = module.cf.cf_hosted_zone_id
    evaluate_target_health = true
  }
}




