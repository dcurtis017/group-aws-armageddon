locals {
  cf_alb_origin_id = "${var.name_prefix}-alb-origin"
}

data "aws_cloudfront_cache_policy" "use_origin_cache_headers01" {
  name = "UseOriginCacheControlHeaders"
}

# similar to the above but allows you to server different content based on query string
data "aws_cloudfront_cache_policy" "use_origin_cache_headers_qs01" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

# Predefined/Managed Origin Request Policies
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html

# include all values (headers, cookies and query strings) from the viewer request
data "aws_cloudfront_origin_request_policy" "orp_all_viewer01" {
  name = "Managed-AllViewer"
}

# do not include the host header from the viewer request but include all others
# some origins stop working if the host header contains cloudfront. With this policy the origin's domain name will be used as the host in the header
data "aws_cloudfront_origin_request_policy" "orp_all_viewer_except_host01" {
  name = "Managed-AllViewerExceptHostHeader"
}

# cloudfront -> ALB
#  Static Content Caching
# Cache aggressively and don't forward anything to the origin
# For static content override any Cache Control header from the origin
resource "aws_cloudfront_cache_policy" "static_asset_cache_policy" {
  name        = "${var.name_prefix}-static-asset-cache-policy"
  comment     = "Aggressively cache content in /static/*"
  default_ttl = 8600    # 1 day
  max_ttl     = 3156000 # year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}
resource "aws_cloudfront_cache_policy" "static_asset_fragmentation_cache_policy" {
  name        = "${var.name_prefix}-static-asset-fragmentation-cache-policy"
  comment     = "Add Fragementation cache content in /static/*"
  default_ttl = 8600    # 1 day
  max_ttl     = 3156000 # year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["User-Agent"]
      }
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_origin_request_policy" "static_asset_request_policy" {
  name    = "${var.name_prefix}-static-asset-origin-request-policy"
  comment = "No forwarding for static assets"
  cookies_config {
    cookie_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
}

resource "aws_cloudfront_response_headers_policy" "static_asset_response_header_policy" {
  name    = "${var.name_prefix}-static-asset-response-headers-policy"
  comment = "Add Cache-Control header for all static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true                              # allow cloudfront to replace the Cache-Control header from the origin
      value    = "public, max-age=8600, immutable" # public: cdns and shared caches are allowed, immutable: browsers won't revalidate
    }
  }
}

# DO NOT use caching for API endpoints
# Forward all headers to the origin (https://repost.aws/knowledge-center/cloudfront-authorization-header)
resource "aws_cloudfront_cache_policy" "api_cache_policy" {
  name        = "${var.name_prefix}-api-cache-policy"
  comment     = "Default Policy - Don't Cache -- Will Apply to APIs (/api/*)"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

  }
}

resource "aws_cloudfront_origin_request_policy" "api_request_policy" {
  name    = "${var.name_prefix}-api-origin-request-policy"
  comment = "Forward all API"

  cookies_config {
    cookie_behavior = "all"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
  headers_config {
    header_behavior = "allViewer"
  }
}

resource "aws_cloudfront_cache_policy" "static_with_etag_asset_cache_policy" {
  name        = "${var.name_prefix}-static-asset-cache-policy-with-etag"
  comment     = "Aggressively cache content in /static/index.html with ETag support"
  default_ttl = 5
  max_ttl     = 10
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_origin_request_policy" "static_with_etag_origin_request_policy" {
  name = "${var.name_prefix}-static-asset-origin-request-policy-with-etag"
  cookies_config {
    cookie_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["if-none-match", "if-modified-since"]
    }
  }
}

resource "aws_cloudfront_distribution" "lab_cf" {
  enabled         = true
  is_ipv6_enabled = false
  comment         = "${var.name_prefix}-cf"

  origin {
    origin_id   = local.cf_alb_origin_id
    domain_name = var.origin_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = var.secret_header_name
      value = var.secret_header_value
    }
  }

  default_cache_behavior {
    target_origin_id       = local.cf_alb_origin_id # origin to route requests to
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_request_policy.id
    cache_policy_id          = aws_cloudfront_cache_policy.api_cache_policy.id
  }

  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = local.cf_alb_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.use_origin_cache_headers01.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.orp_all_viewer_except_host01.id
  }

  ordered_cache_behavior {
    path_pattern           = "/static/index.html"
    target_origin_id       = local.cf_alb_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.use_origin_cache_headers01.id
    #cache_policy_id          = aws_cloudfront_cache_policy.static_with_etag_asset_cache_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.static_with_etag_origin_request_policy.id
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = local.cf_alb_origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.static_asset_cache_policy.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.static_asset_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.static_asset_response_header_policy.id
  }

  web_acl_id = var.waf_arn
  aliases = [
    var.root_domain_name,
    "${var.app_subdomain}.${var.root_domain_name}"
  ]
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# https://medium.com/versent-tech-blog/new-cloudfront-log-destinations-b19d2cecae63
resource "aws_cloudwatch_log_group" "cf_log_group" {
  name              = var.log_group_name
  retention_in_days = 30
}

resource "aws_cloudwatch_log_delivery_source" "cf_log_delivery_source" {
  name         = "cloudfront-logs-source"
  resource_arn = aws_cloudfront_distribution.lab_cf.arn
  log_type     = "ACCESS_LOGS"
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront_logs_delivery_destination" {
  name          = "cloudfront-logs-destination"
  output_format = "json"
  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.cf_log_group.arn
  }
}

resource "aws_cloudwatch_log_delivery" "cloudfront_logs_delivery" {
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cf_log_delivery_source.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront_logs_delivery_destination.arn
}
