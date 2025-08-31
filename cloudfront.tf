resource "aws_cloudfront_distribution" "portfolio_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Minato Portfolio CDN"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.portfolio_site.website_endpoint
    origin_id   = "s3-portfolio-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.access_log.bucket_domain_name # ログ出力先
    prefix          = "cloudfront-access/"                        # プレフィックス
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-portfolio-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 独自ドメイン不要な場合はこれでOK
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "minato-portfolio-cdn"
  }
}
