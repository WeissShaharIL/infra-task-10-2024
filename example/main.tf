terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = {
    Environment = "Production"
    Owner       = "Microsoft"
    ManagedBy   = "Terraform"
  }
}

provider "aws" {
  region = var.aws_region
}

module "compute" {
  source      = "../"
  apps        = var.apps
  common_tags = local.common_tags
}