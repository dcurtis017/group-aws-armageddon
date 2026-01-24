output "certificate_arn" {
  value = aws_acm_certificate.ssl_certificate.arn
}

output "primary_domain_zone_id" {
  value = data.aws_route53_zone.primary_domain_zone.id
}
