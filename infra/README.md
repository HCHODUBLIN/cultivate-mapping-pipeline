# Infra

Infrastructure and DevOps utilities for the CULTIVATE mapping pipeline.

## Directory Structure

```
infra/
├── azure/                    # Azure Blob Storage integration
│   └── azure_blob_sync.py   # Python CLI for blob operations
└── scripts/
    ├── convert_gold_to_powerbi_csv.py
    └── convert_powerbi_to_gold.py
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
./infra/azure/install_cli.sh

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
./infra/azure/sync.sh upload-all ./data

# Download from Azure
./infra/azure/sync.sh download-all

# Use Python script directly for more control
python infra/azure/blob_sync.py list raw/
python infra/azure/blob_sync.py upload ./data/file.csv raw/file.csv
```

---

## Analysis Scripts

Note: Analysis-specific scripts are organized by research phase under `exploration/*/scripts/`:
- `exploration/2024/scripts/` - Original 2024 analysis scripts (completed)
- `exploration/2025/01/scripts/` - Manual verification compilation (2025/01, completed)
- `exploration/2025/02/scripts/` - Prompt engineering experiments (2025/02, completed)
- `exploration/2026/01/scripts/` - Duplication detection (2026/01, completed)
- `exploration/2026/02/scripts/` - Query design improvements (2026/02, in progress)

See [exploration/README.md](../exploration/README.md) for details.
