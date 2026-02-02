# Azure Upload Guide - ShareCity200 CSV

## Quick Upload Instructions

**File to upload:**
```
data/bronze/duplication/sharecity200-export-1768225380870.csv
```

**Destination:**
```
Azure Storage Account: cultivatedata
Container: cultivatedata
Path: bronze/duplication/sharecity200-export-1768225380870.csv
```

---

## Option 1: Azure Portal (Web Browser)

### Steps:

1. **Go to Azure Portal**
   - Navigate to: https://portal.azure.com
   - Sign in with your credentials

2. **Navigate to Storage Account**
   - Search for "Storage accounts" in the top search bar
   - Select your storage account: `cultivatedata`

3. **Open Containers**
   - In the left menu, click "Containers" under "Data storage"
   - Click on the `cultivatedata` container

4. **Create Folder Structure** (if not exists)
   - Click "Upload" button
   - Click "Advanced" to show folder options
   - In "Upload to folder" field, type: `bronze/duplication`

5. **Upload File**
   - Click "Browse for files" or drag and drop
   - Select: `data/bronze/duplication/sharecity200-export-1768225380870.csv`
   - Click "Upload"

6. **Verify**
   - Navigate to `bronze/duplication/` folder
   - Confirm file appears with correct name and size (774 KB)

---

## Option 2: Azure Storage Explorer (Desktop App)

### Prerequisites:
- Download Azure Storage Explorer: https://azure.microsoft.com/en-us/products/storage/storage-explorer/

### Steps:

1. **Connect to Storage Account**
   - Open Azure Storage Explorer
   - Click "Connect" icon
   - Select "Storage account or service"
   - Choose "Account name and key"
   - Enter:
     - Display name: `CULTIVATE Data`
     - Account name: `cultivatedata`
     - Account key: (from your .env file: `$AZURE_STORAGE_KEY`)

2. **Navigate to Container**
   - Expand "Storage Accounts" → `cultivatedata` → "Blob Containers"
   - Click on `cultivatedata` container

3. **Create Folder Structure**
   - Click "New Folder" button
   - Create: `bronze` folder
   - Inside `bronze`, create: `duplication` folder

4. **Upload File**
   - Navigate to `bronze/duplication/` folder
   - Click "Upload" → "Upload Files"
   - Select file: `data/bronze/duplication/sharecity200-export-1768225380870.csv`
   - Click "Upload"

5. **Verify**
   - Refresh the folder
   - Confirm file is uploaded (774 KB)

---

## Option 3: Azure CLI (Command Line)

### Prerequisites:
```bash
# Install Azure CLI if not installed
# macOS:
brew install azure-cli

# Login
az login
```

### Upload Command:

```bash
# Load environment variables
source .env

# Upload file
az storage blob upload \
  --account-name cultivatedata \
  --account-key "$AZURE_STORAGE_KEY" \
  --container-name cultivatedata \
  --name bronze/duplication/sharecity200-export-1768225380870.csv \
  --file data/bronze/duplication/sharecity200-export-1768225380870.csv \
  --overwrite

# Verify upload
az storage blob list \
  --account-name cultivatedata \
  --account-key "$AZURE_STORAGE_KEY" \
  --container-name cultivatedata \
  --prefix bronze/duplication/ \
  --output table
```

---

## Verification

After upload, verify the file is accessible:

### In Azure Portal:
- Navigate to: Storage account → Containers → cultivatedata → bronze/duplication/
- File should appear: `sharecity200-export-1768225380870.csv`
- Size: ~774 KB
- Type: application/vnd.ms-excel or text/csv

### Using Azure CLI:
```bash
az storage blob show \
  --account-name cultivatedata \
  --account-key "$AZURE_STORAGE_KEY" \
  --container-name cultivatedata \
  --name bronze/duplication/sharecity200-export-1768225380870.csv \
  --query "{name:name, size:properties.contentLength, type:properties.contentSettings.contentType}"
```

---

## Next Steps

Once upload is complete:

1. ✅ **Run Snowflake SQL** to create table and load data:
   ```bash
   snowsql -f snowflake/08_bronze_sharecity200.sql
   ```

2. ✅ **Verify data in Snowflake:**
   ```sql
   SELECT COUNT(*) FROM bronze_sharecity200_raw;
   -- Expected: 3,140 rows
   ```

3. ✅ **Run dbt comparison model:**
   ```bash
   dbt run --select fsi_deduplication_impact
   ```

4. ✅ **View results:**
   ```bash
   dbt show --select fsi_deduplication_impact
   ```

---

## Troubleshooting

### Error: "Account key is invalid"
- Check `.env` file for correct `AZURE_STORAGE_KEY`
- Make sure there are no extra spaces or quotes

### Error: "Container not found"
- Verify container name is exactly: `cultivatedata`
- Check you're connected to the correct storage account

### Error: "Blob already exists"
- Add `--overwrite` flag to Azure CLI command
- Or delete existing blob first in Portal/Storage Explorer

---

**Current Status:** Ready to upload
**File Location:** `data/bronze/duplication/sharecity200-export-1768225380870.csv`
**Destination:** Azure Blob Storage → cultivatedata container → bronze/duplication/

