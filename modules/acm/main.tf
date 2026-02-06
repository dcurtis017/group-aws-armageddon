terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_route53_zone" "primary_domain_zone" {
  name         = var.root_domain_name
  private_zone = false
}

resource "aws_acm_certificate" "ssl_certificate" {
  domain_name       = var.root_domain_name
  validation_method = "DNS"
  subject_alternative_names = [ # allows a single cert to secure multiple domains, subdomain...
    "*.${var.root_domain_name}"
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_verfication_record" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.ssl_certificate.domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.primary_domain_zone.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "acm_cert_validation" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [aws_route53_record.acm_verfication_record.fqdn]
}

