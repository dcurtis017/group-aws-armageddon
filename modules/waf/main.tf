# WAF ACL Setup
resource "aws_wafv2_web_acl" "waf_acl" {

  name  = "${var.name_prefix}-waf"
  scope = var.waf_scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet" # https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-baseline.html#aws-managed-rule-groups-baseline-crs
        vendor_name = "AWS"

        # we can use this to override specific rules in the managed rule group TODO: make sure this is in notes
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-waf-common-rules"
      sampled_requests_enabled   = true
    }
  }
  tags = {
    Name = "${var.name_prefix}-waf"
  }
}

resource "aws_wafv2_web_acl_association" "waf_acl_association" {
  count = var.enable_waf && var.include_waf_acl_association ? 1 : 0

  resource_arn = var.associate_waf_with_resource_arn
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
}

resource "aws_cloudwatch_log_group" "waf_log_group01" {
  count = var.enable_waf_logging ? 1 : 0

  # NOTE: AWS requires WAF log destination names start with aws-waf-logs- (students must not rename this).
  name              = "aws-waf-logs-${var.name_prefix}-webacl01"
  retention_in_days = 7

  tags = {
    Name = "${var.name_prefix}-waf-log-group01"
  }
  region = "us-east-1"
}


resource "aws_wafv2_web_acl_logging_configuration" "waf_logging01" {
  count = var.enable_waf_logging ? 1 : 0

  resource_arn = aws_wafv2_web_acl.waf_acl.arn
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_log_group01[0].arn
  ]

  # TODO: Students can add redacted_fields (authorization headers, cookies, etc.) as a stretch goal.
  # redacted_fields { ... }

  depends_on = [aws_wafv2_web_acl.waf_acl]
  region     = "us-east-1"
}

# TODO: add s3 and kinesis firehose as logging destinations -- it's possible that maybe you can just add to the waf_logging01 log_destination_configs array. Maybe make the array in locals based on variables and using list concatenation??
