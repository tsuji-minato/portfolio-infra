output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.portfolio_cdn.domain_name}"
}
