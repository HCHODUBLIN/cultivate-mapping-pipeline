# Terraform — CULTIVATE S3 Infrastructure

Manages the AWS S3 bucket that stores all CULTIVATE mapping pipeline data.

## What it manages

| Resource | Description |
|----------|-------------|
| **S3 Bucket** | `cultivate-mapping-data` (eu-north-1) — raw, automation, exploration, and verified data |
| **Versioning** | Enabled — protects against accidental deletion |
| **Public Access Block** | All public access blocked |

## Quick Start

```bash
cd terraform

terraform init
terraform plan
terraform apply
```

## Files

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and AWS provider version constraints |
| `provider.tf` | AWS provider configuration |
| `variables.tf` | Region and bucket name variables |
| `s3.tf` | S3 bucket, versioning, public access block |
| `outputs.tf` | Bucket name, ARN, region |
| `terraform.tfvars` | Your variable values (committed — non-sensitive) |

## Importing the existing bucket

The S3 bucket already exists (created manually). On first run, import it into state:

```bash
terraform import aws_s3_bucket.cultivate cultivate-mapping-data
terraform import aws_s3_bucket_versioning.cultivate cultivate-mapping-data
terraform import aws_s3_bucket_public_access_block.cultivate cultivate-mapping-data
```

After import, `terraform plan` should show no changes (or only metadata updates).
