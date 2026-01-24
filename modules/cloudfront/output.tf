output "cf_domain_name" {
  value = aws_cloudfront_distribution.lab_cf.domain_name
}

output "cf_hosted_zone_id" {
  value = aws_cloudfront_distribution.lab_cf.hosted_zone_id
}
