resource "aws_s3_bucket" "cultivate" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "cultivate" {
  bucket = aws_s3_bucket.cultivate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cultivate" {
  bucket = aws_s3_bucket.cultivate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
