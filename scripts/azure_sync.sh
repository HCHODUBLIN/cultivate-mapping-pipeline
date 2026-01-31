#!/bin/bash
# Azure Blob Storage Sync Script
# Quick commands for syncing data between local and Azure Blob

# Configuration
STORAGE_ACCOUNT="your_storage_account_name"  # ← 너의 Storage Account 이름으로 바꿔
CONTAINER="cultivatedata"
LOCAL_DIR="/Users/hyunjicho/Documents/cultivate-mapping-pipeline/data_azure_sync"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
list_blobs() {
    echo -e "${BLUE}Listing blobs in container '${CONTAINER}'...${NC}"
    az storage blob list \
        --account-name $STORAGE_ACCOUNT \
        --container-name $CONTAINER \
        --auth-mode login \
        --output table
}

download_all() {
    echo -e "${BLUE}Downloading all blobs to ${LOCAL_DIR}...${NC}"
    mkdir -p "$LOCAL_DIR"
    az storage blob download-batch \
        --account-name $STORAGE_ACCOUNT \
        --source $CONTAINER \
        --destination "$LOCAL_DIR" \
        --auth-mode login
    echo -e "${GREEN}✓ Download complete!${NC}"
}

download_folder() {
    local folder=$1
    echo -e "${BLUE}Downloading folder '${folder}' to ${LOCAL_DIR}/${folder}...${NC}"
    mkdir -p "$LOCAL_DIR/$folder"
    az storage blob download-batch \
        --account-name $STORAGE_ACCOUNT \
        --source $CONTAINER \
        --destination "$LOCAL_DIR" \
        --pattern "${folder}/*" \
        --auth-mode login
    echo -e "${GREEN}✓ Download complete!${NC}"
}

upload_all() {
    local source_dir=$1
    echo -e "${BLUE}Uploading ${source_dir} to container '${CONTAINER}'...${NC}"
    az storage blob upload-batch \
        --account-name $STORAGE_ACCOUNT \
        --destination $CONTAINER \
        --source "$source_dir" \
        --auth-mode login
    echo -e "${GREEN}✓ Upload complete!${NC}"
}

sync_to_local() {
    echo -e "${BLUE}Syncing from Azure to local...${NC}"
    download_all
}

sync_to_azure() {
    local source_dir=$1
    echo -e "${BLUE}Syncing from local to Azure...${NC}"
    upload_all "$source_dir"
}

# Main
case "$1" in
    list)
        list_blobs
        ;;
    download-all)
        download_all
        ;;
    download-folder)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify folder name${NC}"
            echo "Usage: $0 download-folder <folder_name>"
            exit 1
        fi
        download_folder "$2"
        ;;
    upload-all)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify source directory${NC}"
            echo "Usage: $0 upload-all <source_directory>"
            exit 1
        fi
        upload_all "$2"
        ;;
    sync-from-azure)
        sync_to_local
        ;;
    sync-to-azure)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify source directory${NC}"
            echo "Usage: $0 sync-to-azure <source_directory>"
            exit 1
        fi
        sync_to_azure "$2"
        ;;
    *)
        echo "Azure Blob Storage Sync Tool"
        echo ""
        echo "Usage:"
        echo "  $0 list                              - List all blobs"
        echo "  $0 download-all                      - Download all blobs to local"
        echo "  $0 download-folder <folder>          - Download specific folder"
        echo "  $0 upload-all <directory>            - Upload directory to Azure"
        echo "  $0 sync-from-azure                   - Sync from Azure to local"
        echo "  $0 sync-to-azure <directory>         - Sync from local to Azure"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 download-folder raw/source_data"
        echo "  $0 upload-all ./data_reviewed"
        echo "  $0 sync-from-azure"
        ;;
esac
