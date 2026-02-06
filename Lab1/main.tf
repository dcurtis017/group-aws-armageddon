locals {
  ssm_and_secret_prefix = "lab"
  alb_log_prefix        = "alb-logs"
  secret_header_name    = "ChewyLives"
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
    Name = "${var.name_prefix}-logs-bucket"
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
  associate_waf_with_resource_arn = module.web_app.alb_arn
  waf_scope                       = "REGIONAL"
  include_waf_acl_association     = true
}

# RDS 
module "rds" {
  source = "../modules/rds"

  ssm_and_secret_prefix      = local.ssm_and_secret_prefix
  logs_bucket                = aws_s3_bucket.logs_bucket.arn
  name_prefix                = var.name_prefix
  allowed_sg_ids             = [module.web_app.web_instance_sg_id] # sg for ec2 
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

  name_prefix             = var.name_prefix
  region                  = var.region
  ssm_and_secret_prefix   = local.ssm_and_secret_prefix
  db_secret_name          = module.rds.db_secret_name
  vpc_id                  = module.vpc.vpc_id
  ami_id                  = var.ami_id
  instance_type           = var.instance_type
  publish_custom_metric   = true
  enable_alb_access_logs  = var.enable_alb_access_logs
  alb_log_prefix          = local.alb_log_prefix
  enabled_alb_tls         = true
  vpc_endpoint_services   = var.vpc_endpoint_services
  vpc_endpoint_subnet_ids = [module.vpc.private_subnet_ids[0]]
  alb_subnets             = module.vpc.public_subnet_ids
  logs_bucket_id          = aws_s3_bucket.logs_bucket.id
  secret_header_name      = local.secret_header_name
  certificate_arn         = module.acm.certificate_arn
  instance_subnet         = module.vpc.private_subnet_ids[0]
  secret_header_value     = random_string.bucket_suffix.result
}

# alias so alb can use root domain
resource "aws_route53_record" "alb_app_alias" {
  zone_id = module.acm.primary_domain_zone_id
  name    = "app" # if you use the sub and root domain it will create a record like app.example.com.example.com. if you want the root just leave name blank
  type    = "A"
  # ttl     = 120 # can't use ttl with alias

  alias {
    name                   = module.web_app.alb_dns_name
    zone_id                = module.web_app.alb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "alb_alias" {
  zone_id = module.acm.primary_domain_zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = module.web_app.alb_dns_name
    zone_id                = module.web_app.alb_zone_id
    evaluate_target_health = true
  }
}

# cloudwatch metric, alarm and dashboard for lab
resource "aws_cloudwatch_metric_alarm" "lab1_db_connection_errors_alarm" {
  alarm_name          = "${var.name_prefix}-db-connection-errors-alarm"
  alarm_description   = "Alarm when there are more than 3 connection errors within 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1 # how many periods to evaluate the metric over
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300 # how large a period is
  statistic           = "Sum"
  threshold           = 3              # how many failures to tolerate before alarming
  treat_missing_data  = "notBreaching" # this way when we don't send data the alarm won't go into or stay in the alarm state

  alarm_actions = [aws_sns_topic.lab1_alarms_topic.arn]
  dimensions = {
    DBInstanceIdentifier = module.rds.rds_instance_id
  }
  tags = {
    Name = "${var.name_prefix}-alarm-db-fail"
  }

}

# SNS Topic for Alarms
resource "aws_sns_topic" "lab1_alarms_topic" {
  name = "${var.name_prefix}-alarms-topic"
}

resource "aws_sns_topic_subscription" "lab1_alarm_subscription" {
  topic_arn = aws_sns_topic.lab1_alarms_topic.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# Alarm for 5xx errors on load balancer
resource "aws_cloudwatch_metric_alarm" "alb_5xx_error_alarm" {
  alarm_name          = "${var.name_prefix}-alb-5xx-error-alarm"
  alarm_description   = "Alarm when ALB 5xx errors exceed threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_error_evaluation_periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  threshold           = var.alb_5xx_error_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.lab1_alarms_topic.arn]

  dimensions = {
    LoadBalancer = module.web_app.alb_arn
  }
  tags = {
    Name = "${var.name_prefix}-alarm-5xx-fail"
  }
}


# Dashboard
resource "aws_cloudwatch_dashboard" "dashboard1" {
  dashboard_name = "${var.name_prefix}-dashboard"


  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0 # 0-23
        y      = 0 # 0 to any
        width  = 12
        height = 6
        properties = {
          metrics = [
            # first metric is AWS/ApplicationELB.RequestCount.LoadBalancer.[load balancer arn suffix]
            # namespace, metric name, dimension key, dimension value, dimension key, dimension value, ...
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.web_app.alb_arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", module.web_app.alb_arn_suffix] # . means same namespace as previous
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.web_app.alb_arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ALB: Target Response Time"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["Lab/RDSApp", "DBConnectionErrors", "DBInstanceIdentifier", module.rds.rds_instance_id]

          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "RDS: DB Connection Errors"
        }
      }
    ]
  })
}

