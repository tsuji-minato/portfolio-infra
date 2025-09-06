resource "aws_s3_bucket" "portfolio_site" {
  bucket        = var.site_bucket_name
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
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = "${aws_s3_bucket.portfolio_site.arn}/*"
    }]
  })
}

resource "aws_s3_bucket" "access_log" {
  bucket        = var.logs_bucket_name
  force_destroy = false

  tags = {
    Name        = "PortfolioAccessLogs"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "access_log_controls" {
  bucket = aws_s3_bucket.access_log.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket_acl" "access_log_acl" {
  bucket = aws_s3_bucket.access_log.id

  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }

    grant {
      permission = "FULL_CONTROL"
      grantee {
        type = "CanonicalUser"
        id   = data.aws_canonical_user_id.current.id
      }
    }

    grant {
      permission = "WRITE"
      grantee {
        type = "CanonicalUser"
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      }
    }

    grant {
      permission = "READ_ACP"
      grantee {
        type = "CanonicalUser"
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
      }
    }
  }
}
