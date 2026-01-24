# Web Service Module

## Purpose

Deploys a complete web application stack with EC2 instance, Application Load Balancer (ALB), security groups, optional TLS termination, and access logging for high availability and security.

## Variables

| Variable                 | Type   | Default    | Description                                 |
| ------------------------ | ------ | ---------- | ------------------------------------------- |
| `name_prefix`            | string | "myapp"    | Prefix for naming resources                 |
| `region`                 | string | _required_ | AWS region for deployment                   |
| `vpc_id`                 | string | _required_ | VPC ID where resources will be placed       |
| `ami_id`                 | string | _required_ | AMI ID for the EC2 instance                 |
| `instance_type`          | string | _required_ | EC2 instance type (e.g., t2.micro)          |
| `db_secret_name`         | string | _required_ | Name of the database credentials secret     |
| `ssm_and_secret_prefix`  | string | "lab"      | Prefix for SSM Parameter Store              |
| `publish_custom_metric`  | bool   | false      | Enable publishing custom CloudWatch metrics |
| `enable_alb_access_logs` | bool   | false      | Enable ALB access logging to S3             |
| `alb_log_prefix`         | string | "alb-logs" | S3 prefix for ALB logs                      |
| `enabled_alb_tls`        | bool   | false      | Enable TLS on ALB                           |

## Outputs

| Output               | Description                                 |
| -------------------- | ------------------------------------------- |
| `web_instance_id`    | EC2 instance ID                             |
| `web_instance_arn`   | EC2 instance ARN                            |
| `web_instance_sg_id` | Security group ID for EC2 instance          |
| `alb_id`             | Application Load Balancer ID                |
| `alb_arn`            | ALB ARN                                     |
| `alb_sg_id`          | ALB security group ID                       |
| `alb_dns_name`       | DNS name for accessing the ALB              |
| `alb_zone_id`        | Hosted zone ID for ALB (useful for Route53) |
| `alb_arn_suffix`     | ALB ARN suffix for CloudWatch alarms        |

## Resources Created

- EC2 Instance with web server
- Application Load Balancer
- Target Group for ALB
- ALB Listener (HTTP/HTTPS)
- Security Groups (EC2 and ALB)
- IAM Role for EC2 (Secrets Manager and SSM access)
- Optional S3 bucket for ALB access logs
