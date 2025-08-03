# S3 bucket for storing SSM command outputs
resource "aws_s3_bucket" "ssm_output_bucket" {
  bucket = "${var.s3_bucket_name}-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "SSM Output Bucket"
    Environment = "Development"
  }
}

# Random string for unique bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "ssm_output_bucket_versioning" {
  bucket = aws_s3_bucket.ssm_output_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_output_bucket_encryption" {
  bucket = aws_s3_bucket.ssm_output_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "ssm_output_bucket_pab" {
  bucket = aws_s3_bucket.ssm_output_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
