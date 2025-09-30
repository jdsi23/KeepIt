# DynamoDB: keepit-items
resource "aws_dynamodb_table" "items" {
  name         = "${var.name_prefix}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"
  attribute { name = "pk"; type = "S" }
  attribute { name = "sk"; type = "S" }

  global_secondary_index {
    name            = "gsi1"
    hash_key        = "gsi1pk"
    range_key       = "gsi1sk"
    projection_type = "ALL"
  }

  attribute { name = "gsi1pk"; type = "S" }
  attribute { name = "gsi1sk"; type = "S" }
}

# DynamoDB: keepit-reminders (with TTL)
resource "aws_dynamodb_table" "reminders" {
  name         = "${var.name_prefix}-reminders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"
  attribute { name = "pk"; type = "S" }
  attribute { name = "sk"; type = "S" }

  ttl { attribute_name = "expires_at"; enabled = true }
}

# S3 bucket for media (private, presigned only)
resource "aws_s3_bucket" "media" {
  bucket = "${var.name_prefix}-media"
}

resource "aws_s3_bucket_ownership_controls" "media" {
  bucket = aws_s3_bucket.media.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default = var.kms_key_arn != "" ? {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    } : {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

# CORS to allow presigned PUT/POST from mobile app origins (adjust as needed)
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  cors_rule {
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]   # tighten later (add app scheme/web)
    allowed_headers = ["*"]
    max_age_seconds = 300
  }
}
