variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "eu-north-1"
}

variable "bucket_name" {
  description = "S3 bucket for CULTIVATE mapping data"
  type        = string
  default     = "cultivate-mapping-data"
}
