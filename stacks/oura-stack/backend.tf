terraform {
  backend "s3" {
    bucket         = "minato-portfolio-tfstate"
    key            = "oura-stack/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "minato-tf-lock"
    encrypt        = true
  }
}
