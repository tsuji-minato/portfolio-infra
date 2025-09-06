provider "aws" {
  region = "us-east-1" # CloudFront用に必須
}

module "static_site" {
  source            = "../../modules/static-site"
  site_bucket_name  = var.site_bucket_name
  logs_bucket_name  = var.logs_bucket_name
}
