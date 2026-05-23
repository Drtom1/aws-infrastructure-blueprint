
# Module: S3
# Creates a secure, resilient S3 bucket with:
#   - Versioning and lifecycle management
#   - Server-side encryption
#   - Access logging
#   - Public access fully blocked
#   - Inventory reporting (optional)
#   - Object Lock for compliance (optional)

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Logging bucket for S3 access logs
resource "aws_s3_bucket" "logging" {
  count         = var.enable_logging ? 1 : 0
  bucket        = "${local.name_prefix}-logs-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_bucket

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs"
    }
  )
}

# Block public access to logging bucket
resource "aws_s3_bucket_public_access_block" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Main S3 bucket
resource "aws_s3_bucket" "main" {
  bucket              = "${local.name_prefix}-storage-${random_id.bucket_suffix.hex}"
  force_destroy       = var.force_destroy_bucket
  object_lock_enabled = var.enable_object_lock

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-storage"
    }
  )
}

# Random suffix prevents bucket name collisions globally
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enable S3 access logging
resource "aws_s3_bucket_logging" "main" {
  count         = var.enable_logging ? 1 : 0
  bucket        = aws_s3_bucket.main.id
  target_bucket = aws_s3_bucket.logging[0].id
  target_prefix = "access-logs/"
}

# Block ALL Public Access
resource "aws_s3_bucket_public_access_block" "main" {
  count  = var.enable_block_public_access ? 1 : 0
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Lifecycle Rules
# Automatically manage object storage tiers to optimize costs
# while maintaining data availability
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "intelligent-tiering"
    status = "Enabled"

    # Transition current versions to Standard-IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after specified days for archival
    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    # Manage old versions
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  rule {
    id     = "expire-incomplete-uploads"
    status = "Enabled"

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 Inventory for daily bucket analysis (optional)
resource "aws_s3_bucket_inventory" "main" {
  count  = var.enable_inventory ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "${local.name_prefix}-daily-inventory"

  included_object_versions = "All"

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.main.arn
      prefix     = var.inventory_prefix

      encryption {
        sse_s3 {}
      }
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
  ]
}
