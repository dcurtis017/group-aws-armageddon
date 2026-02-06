terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_ec2_managed_prefix_list" "cloudfront_prefixes" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# EC2
data "aws_iam_policy_document" "lab_1_assume_role_policy" {
  statement {
    sid    = "EC2AssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lab_1_ec2_role" {
  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.lab_1_assume_role_policy.json
}

# allow management of instance using ssm (no need for ssh!!)
resource "aws_iam_role_policy_attachment" "lab_1_ec2_ssm_attachment" {
  role       = aws_iam_role.lab_1_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# allow reading and writing from aws secrets manager
resource "aws_iam_role_policy_attachment" "lab_1_ec2_secrets_manager_attachment" {
  role       = aws_iam_role.lab_1_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# allows creating log streams, log groups...https://docs.aws.amazon.com/aws-managed-policy/latest/reference/CloudWatchAgentServerPolicy.html
resource "aws_iam_role_policy_attachment" "lab_1_ec2_cw_attachment" {
  role       = aws_iam_role.lab_1_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "lab_1_ec2_secret_policy" {
  name = "${var.name_prefix}-ec2-secret-policy"
  role = aws_iam_role.lab_1_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue", # get encrypted secret value
          "secretsmanager:DescribeSecret"  # get secret metadata lik arn, version ids, rotation schedule...
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.db_secret_name}"
      },
      {
        Effect : "Allow",
        Action : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource : "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.ssm_and_secret_prefix}/db/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "${var.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.lab_1_ec2_role.name
}
resource "aws_security_group" "web_instance_sg" {
  name        = "${var.name_prefix}-web-instance-sg"
  description = "Web Server Instance Security Group"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_egress_rule" "web_instance_sg_allow_all_outbound" {
  security_group_id = aws_security_group.web_instance_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_instance_sg_allow_http_inbound" {
  security_group_id = aws_security_group.web_instance_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_cloudwatch_log_group" "lab_1_ec2_log_group" {
  name              = "/aws/ec2/${var.name_prefix}-ec2-log-group"
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-ec2-log-group"
  }
}

resource "aws_instance" "web_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.instance_subnet
  vpc_security_group_ids = [aws_security_group.web_instance_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.web_instance_profile.name

  #TODO split up user_data.sh to make it cleaner
  user_data = templatefile("${path.module}/user_data.sh", {
    db_secret_name        = var.db_secret_name,
    log_group             = aws_cloudwatch_log_group.lab_1_ec2_log_group.name
    publish_custom_metric = var.publish_custom_metric
    aws_region            = var.region
  })

  tags = {
    Name = "${var.name_prefix}-web-sg"
  }
}

# ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_allow_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allow_http_inbound" {
  count             = var.restrict_alb_to_cloudfront ? 0 : 1
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allow_https_inbound" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allow_cloudfront_prefix_https_inbound" {
  count             = var.restrict_alb_to_cloudfront ? 1 : 0
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront_prefixes.id
}

resource "aws_lb" "alb" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.alb_subnets

  access_logs {
    bucket  = var.logs_bucket_id
    prefix  = var.alb_log_prefix
    enabled = var.enable_alb_access_logs
  }
  tags = {
    Name = "${var.name_prefix}-alb "
  }
}

resource "aws_lb_target_group" "http_target_group" {
  name     = "${var.name_prefix}-tg"
  port     = 80 # target group receives traffic on this port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399" # http codes to check for
    interval            = 30        # seconds between health checks
    timeout             = 5         # time in seconds that no response means failed health check
    healthy_threshold   = 2         # number of required successes to be healthy
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  target_group_arn = aws_lb_target_group.http_target_group.arn
  target_id        = aws_instance.web_instance.id
  port             = 80 # Optional: can override the default TG port -- port target receives traffic on
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  # depends_on = [aws_acm_certificate_validation.acm_cert_validation] # the depenency should be on the web_service module
}

# TODO add listener to redirect http to https

resource "random_password" "origin_header_value" {
  length  = 32
  special = false
}

resource "aws_lb_listener_rule" "custom_header_listener_rule" {
  count        = var.restrict_alb_access_with_header ? 1 : 0
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_target_group.arn
  }

  condition {
    http_header {
      http_header_name = var.secret_header_name
      values           = [var.secret_header_value]
    }
  }
}

resource "aws_lb_listener_rule" "block_rule" {
  count        = var.restrict_alb_access_with_header ? 1 : 0
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 99

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["*"] # apply to any path
    }
  }
}

# vpc endpoints and security groups for them
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.name_prefix}VPC-Endpoint-SG"
  description = "Restrict access to vpc endpoints only to the web server security group"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}VPC-Endpoint-SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_sg_allow_all_outbound" {
  security_group_id = aws_security_group.vpc_endpoint_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_sg_allow_mysql_inbound" {
  security_group_id            = aws_security_group.vpc_endpoint_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.web_instance_sg.id
}

resource "aws_vpc_endpoint" "private_links" {
  count = length(var.vpc_endpoint_services)

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${var.vpc_endpoint_services[count.index]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.vpc_endpoint_subnet_ids
  service_region      = var.region
  private_dns_enabled = true # with this enabled we don't need to update the route table
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "${var.name_prefix}-vpc-endpoint-${var.vpc_endpoint_services[count.index]}"
  }
}
