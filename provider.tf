provider "aws" {
  region = "us-east-1" # バージニア北部（コスト重視で）
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
