resource "aws_s3_bucket" "portfolio_site" {
  bucket = "minato-portfolio-site-20250816"
  force_destroy = false

  tags = {
    Name        = "PortfolioSite"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_website_configuration" "portfolio_site" {
  bucket = aws_s3_bucket.portfolio_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.portfolio_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = ["s3:GetObject"],
        Resource = "${aws_s3_bucket.portfolio_site.arn}/*"
      }
    ]
  })
}
