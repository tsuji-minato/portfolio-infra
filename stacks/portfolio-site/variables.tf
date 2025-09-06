variable "site_bucket_name" {
  description = "静的サイト用S3バケット名"
  type        = string
}

variable "logs_bucket_name" {
  description = "CloudFrontログ出力用バケット名"
  type        = string
}
