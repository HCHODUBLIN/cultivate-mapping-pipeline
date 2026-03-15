# Terraform — CULTIVATE Snowflake Infrastructure

Infrastructure-as-Code for the CULTIVATE food-sharing mapping pipeline on Snowflake.

## What it manages

| Resource | Description |
|----------|-------------|
| **Warehouse** | `FSI_WH` — X-Small, auto-suspend 60s |
| **Database** | `CULTIVATE` |
| **Schemas** | `HC_LOAD_DATA_FROM_CLOUD` (raw), `STAGING`, `INTERMEDIATE`, `MARTS` |
| **File Formats** | JSON (strip array), CSV default, CSV UTF-8 |
| **External Stage** | Azure Blob Storage (optional) |
| **Tables** | 6 Bronze tables (`BRONZE_*`) |
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

## Multi-Environment

```bash
# Dev (default)
terraform apply -var="environment=dev"

# Production
terraform apply -var="environment=prod" -var="warehouse_size=SMALL"
```

## Files

| File | Purpose |
|------|---------|
| `provider.tf` | Snowflake provider configuration |
| `versions.tf` | Terraform and provider version constraints |
| `variables.tf` | Input variables with defaults and validation |
| `database.tf` | Database and schema definitions |
| `warehouse.tf` | Warehouse configuration |
| `file_formats.tf` | File format definitions for data loading |
| `stages.tf` | External stage for Azure Blob (conditional) |
| `tables.tf` | Bronze/raw layer table definitions |
| `roles.tf` | RBAC roles, hierarchy, and privilege grants |
| `outputs.tf` | Output values for reference |

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

**Required GitHub Secrets:** `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE` (shared with dbt CI)

### Full Pipeline Flow

```
terraform/ changes ──► Terraform CI ──► infra provisioned
                                              │
dbt/ changes ────────► Snowflake CI ──► models built & tested
                                              │
                                        Dashboard reads from marts
```
