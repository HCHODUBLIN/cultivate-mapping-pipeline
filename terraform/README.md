# Terraform — CULTIVATE Snowflake Infrastructure

Infrastructure-as-Code for the CULTIVATE food-sharing mapping pipeline on Snowflake.

## What it manages

| Resource | Description |
|----------|-------------|
| **Warehouse** | `FSI_WH` — X-Small, auto-suspend 60s |
| **Database** | `CULTIVATE` |
| **Schemas** | `HC_LOAD_DATA_FROM_CLOUD` (raw), `STAGING`, `INTERMEDIATE`, `MARTS` |
| **File Formats** | JSON (strip array), CSV default |
| **External Stage** | AWS S3 (optional) |
| **Roles & Grants** | `CULTIVATE_TRANSFORMER`, `CULTIVATE_READER`, `CULTIVATE_LOADER` |

## Architecture

```
CULTIVATE_LOADER ──► Raw Schema ──► (dbt) ──► Staging ──► Intermediate ──► Marts
                     CULTIVATE_TRANSFORMER (read raw, write staging/int/marts)
                                                                    CULTIVATE_READER (read marts)
```

## Quick Start

```bash
cd terraform

# 1. Configure credentials
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Snowflake credentials

# 2. Initialize
terraform init

# 3. Preview changes
terraform plan

# 4. Apply
terraform apply
```

## Files (dependency order)

| # | File | Purpose |
|---|------|---------|
| 1 | `versions.tf` | Terraform and provider version constraints |
| 2 | `variables.tf` | Input variables with defaults and validation |
| 3 | `provider.tf` | Snowflake provider connection (uses variables) |
| 4 | `database.tf` | Database and schema definitions |
| 5 | `warehouse.tf` | Warehouse configuration |
| 6 | `roles.tf` | RBAC roles, hierarchy, and privilege grants |
| 7 | `file_formats.tf` | File format definitions for data loading |
| 8 | `stages.tf` | External stage — AWS S3 (depends on database, schema, file format) |
| 9 | `outputs.tf` | Output values for reference |

## CI/CD Integration

GitHub Actions workflow (`.github/workflows/terraform-ci.yml`) runs automatically on changes to `terraform/`:

```
PR opened ──► fmt check ──► validate ──► plan (posted as PR comment)
                                              │
merge to main ──────────────────────────► apply (requires approval)
```

| Stage | Trigger | What it does |
|-------|---------|-------------|
| **Format** | All PRs | `terraform fmt -check` — enforces consistent style |
| **Validate** | All PRs | `terraform validate` — catches syntax and config errors |
| **Plan** | All PRs | `terraform plan` — posts infrastructure diff as PR comment |
| **Apply** | Merge to main | `terraform apply` — provisions changes (requires `production` environment approval) |

**Required GitHub Secrets:** `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE` (shared with dbt CI), plus `AWS_IAM_ROLE_ARN` and `AWS_S3_BUCKET` if using the S3 external stage

### Full Pipeline Flow

```
terraform/ changes ──► Terraform CI ──► infra provisioned
                                              │
dbt/ changes ────────► Snowflake CI ──► models built & tested
                                              │
                                        Dashboard reads from marts
```
