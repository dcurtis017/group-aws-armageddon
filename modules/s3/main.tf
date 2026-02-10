terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

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
      },
      {
        Sid    = "AllowVPCFlowLogs"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com" # this is case sensitive for the word 'Service'
        }
        Action   = ["s3:PutObject", "s3:ListBucket", "s3:GetBucketAcl", "s3:PutBucketAcl"]
        Resource = ["${aws_s3_bucket.logs_bucket.arn}", "${aws_s3_bucket.logs_bucket.arn}/*"]
      },
      {
        Sid    = "AllowCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = ["${aws_s3_bucket.logs_bucket.arn}"]
      },
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
        Condition = {
          "StringEquals" = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
