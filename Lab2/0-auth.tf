terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  default_tags {
    tags = var.default_tags
  }

  region  = var.region
  profile = "default"
}
