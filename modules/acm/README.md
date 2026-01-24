# ACM Module

## Purpose

Creates and validates an AWS Certificate Manager (ACM) SSL/TLS certificate for your domain with DNS validation through Route53, enabling HTTPS for CloudFront distributions.

## Variables

| Variable           | Type   | Default    | Description                          |
| ------------------ | ------ | ---------- | ------------------------------------ |
| `root_domain_name` | string | _required_ | Root domain name (e.g., example.com) |

## Outputs

| Output                   | Description                                   |
| ------------------------ | --------------------------------------------- |
| `certificate_arn`        | ARN of the created ACM certificate            |
| `primary_domain_zone_id` | Route53 hosted zone ID for the primary domain |

## Resources Created

- ACM Certificate with DNS validation
- Route53 DNS validation records
- Certificate validation waiter

## Notes

- The certificate is created in **us-east-1** region for CloudFront compatibility
- DNS validation is performed automatically through Route53
- The certificate includes Subject Alternative Names (SANs) for subdomains
