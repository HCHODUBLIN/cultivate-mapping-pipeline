# Scripts

Infrastructure and DevOps utilities for the CULTIVATE mapping pipeline.

## Directory Structure

```
scripts/
├── infrastructure/
│   └── azure/              # Azure Blob Storage integration
│       ├── install_cli.sh  # Install Azure CLI
│       ├── blob_sync.py    # Python script for blob operations
│       └── sync.sh         # Shell wrapper for syncing
└── release/
    └── make_release.sh     # Release management script
```

## Infrastructure Scripts

### Azure Blob Storage

Azure scripts for syncing data between local storage and Azure Blob Storage.

**Setup:**

1. Create environment configuration:
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your Azure credentials
# Required variables:
#   AZURE_STORAGE_ACCOUNT_NAME=your_account_name
#   AZURE_STORAGE_KEY=your_storage_key
#   AZURE_CONTAINER_NAME=cultivatedata
```

2. Install Azure CLI:
```bash
./scripts/infrastructure/azure/install_cli.sh

# Authenticate
az login
```

3. Install Python dependencies (for blob_sync.py):
```bash
pip install azure-storage-blob azure-identity python-dotenv
```

**Usage:**
```bash
# Sync data to Azure
./scripts/infrastructure/azure/sync.sh upload-all ./data

# Download from Azure
./scripts/infrastructure/azure/sync.sh download-all

# Use Python script directly for more control
python scripts/infrastructure/azure/blob_sync.py list raw/
python scripts/infrastructure/azure/blob_sync.py upload ./data/file.csv raw/file.csv
```

## Release Scripts

**make_release.sh** - Automates release tagging and deployment processes.

---

## Analysis Scripts

Note: Analysis-specific scripts are organized by research phase under `analysis/*/scripts/`:
- `analysis/legacy_2024/scripts/` - Original 2024 analysis scripts (completed)
- `analysis/legacy_2025/01/scripts/` - Manual verification compilation (2025/01, completed)
- `analysis/legacy_2025/02/scripts/` - Prompt engineering experiments (2025/02, completed)
- `analysis/2026/01/scripts/` - Duplication detection (2026/01, completed)
- `analysis/2026/02/scripts/` - Query design improvements (2026/02, in progress)

See [analysis/README.md](../analysis/README.md) for details.
