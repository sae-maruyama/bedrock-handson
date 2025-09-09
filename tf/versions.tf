terraform {
  required_version = ">= 1.6.0"
  
  # S3バックエンドでtfstateを管理
  backend "s3" {
    bucket       = "handson-remote-backend-2509"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.region
}