# CloudFront Module

## Purpose

Configures a CloudFront Content Delivery Network (CDN) distribution to serve content globally with caching, TLS termination, WAF integration, and custom headers for origin authentication.

## Variables

| Variable              | Type   | Default    | Description                                    |
| --------------------- | ------ | ---------- | ---------------------------------------------- |
| `name_prefix`         | string | _required_ | Prefix for naming resources                    |
| `root_domain_name`    | string | _required_ | Root domain name (e.g., example.com)           |
| `app_subdomain`       | string | _required_ | Subdomain for the application (e.g., app)      |
| `acm_certificate_arn` | string | _required_ | ARN of the ACM certificate for HTTPS           |
| `origin_dns_name`     | string | _required_ | DNS name of the origin (ALB DNS)               |
| `secret_header_name`  | string | _required_ | Custom header name for origin authentication   |
| `secret_header_value` | string | _required_ | Custom header value for origin authentication  |
| `waf_arn`             | string | null       | Optional WAF ACL ARN for CloudFront protection |

## Outputs

| Output              | Description                                         |
| ------------------- | --------------------------------------------------- |
| `cf_domain_name`    | CloudFront distribution domain name                 |
| `cf_hosted_zone_id` | Hosted Zone ID for CloudFront (for Route53 aliases) |

## Resources Created

- CloudFront Distribution
- CloudFront Origin Access Control (OAC)
- Optional WAF association
- Custom origin with ALB backend
- Cache behaviors and policies

## Notes

- Custom headers prevent direct access to origin ALB
- CloudFront provides DDoS protection and global caching
- WAF integration adds additional security layer (optional)
