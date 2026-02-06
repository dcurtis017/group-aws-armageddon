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
    tags = merge(
      var.default_tags,
      {
        Resource_Tag = "Japan/Tokyo"
      }
    )
  }

  region  = var.tokyo_region
  profile = "default"
  alias   = "tokyo"
}

provider "aws" {
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Resource_Tag = "Brazil/SaoPaulo"
      }
    )
  }

  region  = var.saopaulo_region
  profile = "default"
  alias   = "saopaulo"
}

provider "aws" {
  default_tags {
    tags = var.default_tags
  }

  region  = var.acm_region
  profile = "default"
}
