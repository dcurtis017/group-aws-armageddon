# WAF Module

## Purpose

Implements AWS WAF (Web Application Firewall) with preconfigured rules to protect web applications from common exploits and attacks, with optional logging and flexible scope (CloudFront or ALB).

## Variables

| Variable                          | Type   | Default    | Description                                                            |
| --------------------------------- | ------ | ---------- | ---------------------------------------------------------------------- |
| `name_prefix`                     | string | _required_ | Prefix for naming resources                                            |
| `enable_waf`                      | bool   | true       | Enable the WAF                                                         |
| `enable_waf_logging`              | bool   | false      | Enable WAF logging to CloudWatch Logs                                  |
| `associate_waf_with_resource_arn` | string | _required_ | ARN of resource to protect (CloudFront, ALB, etc.)                     |
| `waf_scope`                       | string | "REGIONAL" | WAF scope: REGIONAL (ALB/API GW) or CLOUDFRONT                         |
| `include_waf_acl_association`     | bool   | true       | Include WAF association with resource (set false for CLOUDFRONT scope) |

## Outputs

| Output        | Description        |
| ------------- | ------------------ |
| `waf_acl_arn` | ARN of the WAF ACL |

## Resources Created

- WAF Web ACL
- WAF Rules (AWS Managed Rules for common attacks)
- WAF Logging Configuration (optional)
- WAF Association with resource

## Validation Rules

- `waf_scope` must be either "REGIONAL" or "CLOUDFRONT"
- When using CLOUDFRONT scope, set `include_waf_acl_association` to false

## Notes

- AWS Managed Rules are pre-configured for OWASP Top 10 protection
- WAF logs can be sent to CloudWatch Logs for monitoring
- No additional cost when WAF is disabled
