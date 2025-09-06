terraform {
  backend "s3" {
    bucket         = "minato-portfolio-tfstate"
    key            = "portfolio-site.tfstate"
    region         = "us-east-1"
    dynamodb_table = "minato-tf-lock"
    encrypt        = true
  }
}
