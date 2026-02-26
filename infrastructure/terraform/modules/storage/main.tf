# Storage Module
# Creates EBS storage class and other storage resources for Kubernetes

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

# S3 bucket for backups
resource "aws_s3_bucket" "opensearch_backups" {
  bucket = "log-indexer-opensearch-backups-${var.environment}"

  tags = merge(
    var.tags,
    {
      Name = "log-indexer-opensearch-backups-${var.environment}"
    }
  )
}

# Enable versioning for backups
resource "aws_s3_bucket_versioning" "opensearch_backups" {
  bucket = aws_s3_bucket.opensearch_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "opensearch_backups" {
  bucket = aws_s3_bucket.opensearch_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "opensearch_backups" {
  bucket = aws_s3_bucket.opensearch_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy to delete old backups
resource "aws_s3_bucket_lifecycle_configuration" "opensearch_backups" {
  bucket = aws_s3_bucket.opensearch_backups.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

output "backup_bucket_name" {
  description = "S3 bucket name for OpenSearch backups"
  value       = aws_s3_bucket.opensearch_backups.id
}

output "backup_bucket_arn" {
  description = "S3 bucket ARN for OpenSearch backups"
  value       = aws_s3_bucket.opensearch_backups.arn
}
