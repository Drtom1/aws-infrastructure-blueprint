
# Module: S3
# Creates a secure S3 bucket with:
#   - Versioning
#   - Server-side encryption
#   - Public access fully blocked
#   - Lifecycle rules to manage costs

resource "aws_s3_bucket" "main" {
  bucket        = "${var.project_name}-${var.environment}-storage-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy_bucket

  tags = {
    Name = "${var.project_name}-${var.environment}-storage"
  }
}

# Random suffix prevents bucket name collisions globally
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Block ALL Public Access
resource "aws_s3_bucket_public_access_block" "main" {
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
# Automatically move old versions to cheaper storage
# and delete very old ones to control costs
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "expire-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
