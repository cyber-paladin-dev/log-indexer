# Production environment configuration
# Higher availability and security requirements

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "log-indexer/production/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "log-indexer"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/network"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  tags = var.tags
}

module "eks" {
  source = "../../modules/kubernetes"

  environment        = var.environment
  cluster_name       = "${var.project_name}-${var.environment}"
  cluster_version    = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  node_groups = var.node_groups

  tags = var.tags
}

module "storage" {
  source = "../../modules/storage"

  environment = var.environment

  tags = var.tags
}
