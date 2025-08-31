resource "aws_s3_bucket" "portfolio_site" {
  bucket        = "minato-portfolio-site-20250816"
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
    key = "404.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.portfolio_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.portfolio_site.arn}/*"
      }
    ]
  })
}

# アクセスログ設定

resource "aws_s3_bucket" "access_log" {
  bucket        = "minato-portfolio-logs-20250831"
  force_destroy = false

  tags = {
    Name        = "PortfolioAccessLogs"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "access_log_policy" {
  bucket = aws_s3_bucket.access_log.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3ServerLogDelivery",
        Effect = "Allow",
        Principal = {
          Service = "logging.s3.amazonaws.com"
        },
        Action = [
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.access_log.arn}/*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          },
        }
      }
    ]
  })
}

# AWSアカウント情報を取得するdataリソース
data "aws_caller_identity" "current" {}
