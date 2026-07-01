terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform backend state"
  type        = string
  default     = "sarthak-prometheus-tfstate-2026-ap-south-1"
}

variable "backend_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-lock-table"
}

resource "aws_s3_bucket" "terraform_backend" {
  bucket = var.backend_bucket_name

  tags = {
    Name        = "terraform-backend-bucket"
    Owner       = "Sarthak Bhatnagar"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

locals {
  backend_bucket_id = aws_s3_bucket.terraform_backend.id
}

# Ensure required bucket settings exist (whether bucket is pre-existing or just created)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = local.backend_bucket_id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "backend_block" {
  bucket = local.backend_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backend_encryption" {
  bucket = local.backend_bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backend_lifecycle" {
  bucket = local.backend_bucket_id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {
      prefix = "terraform/"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}



# DynamoDB Table for Terraform Lock
resource "aws_dynamodb_table" "terraform_lock" {
  name        = var.backend_lock_table_name
  table_class = "STANDARD"


  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }


  # Enable Server-side Encryption
  server_side_encryption {
    enabled = true
  }


  # Enable Point-in-Time Recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "terraform-lock-table"
    Owner       = "Sarthak Bhatnagar"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
