#!/usr/bin/env python3
"""
Azure Blob Storage Sync Script
Sync files between local directory and Azure Blob Storage
"""

import os
from pathlib import Path
from azure.storage.blob import BlobServiceClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration from environment variables
STORAGE_ACCOUNT_NAME = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
CONTAINER_NAME = os.getenv("AZURE_CONTAINER_NAME", "cultivatedata")
LOCAL_BASE_DIR = Path(os.getenv("AZURE_LOCAL_SYNC_DIR", "./data_azure_sync"))

if not STORAGE_ACCOUNT_NAME:
    raise RuntimeError(
        "❌ AZURE_STORAGE_ACCOUNT_NAME not found. "
        "Please create a .env file from .env.example and set your Azure Storage Account name."
    )

def get_blob_service_client():
    """Get authenticated blob service client"""
    account_url = f"https://{STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
    credential = DefaultAzureCredential()
    return BlobServiceClient(account_url, credential=credential)

def download_blob(blob_name, local_path):
    """Download a single blob to local file"""
    print(f"Downloading: {blob_name} -> {local_path}")

    blob_service_client = get_blob_service_client()
    blob_client = blob_service_client.get_blob_client(
        container=CONTAINER_NAME,
        blob=blob_name
    )

    # Create parent directory if needed
    local_path.parent.mkdir(parents=True, exist_ok=True)

    # Download
    with open(local_path, "wb") as file:
        download_stream = blob_client.download_blob()
        file.write(download_stream.readall())

    print(f"✓ Downloaded: {local_path}")

def upload_blob(local_path, blob_name):
    """Upload a local file to blob"""
    print(f"Uploading: {local_path} -> {blob_name}")

    blob_service_client = get_blob_service_client()
    blob_client = blob_service_client.get_blob_client(
        container=CONTAINER_NAME,
        blob=blob_name
    )

    # Upload
    with open(local_path, "rb") as file:
        blob_client.upload_blob(file, overwrite=True)

    print(f"✓ Uploaded: {blob_name}")

def list_blobs(prefix=""):
    """List all blobs in container with optional prefix"""
    blob_service_client = get_blob_service_client()
    container_client = blob_service_client.get_container_client(CONTAINER_NAME)

    print(f"\nBlobs in container '{CONTAINER_NAME}' (prefix: '{prefix}'):")
    print("-" * 80)

    blobs = container_client.list_blobs(name_starts_with=prefix)
    for blob in blobs:
        size_mb = blob.size / 1024 / 1024
        print(f"{blob.name:60s} {size_mb:8.2f} MB")

    print("-" * 80)

def download_all(prefix="", local_dir=None):
    """Download all blobs with given prefix"""
    if local_dir is None:
        local_dir = LOCAL_BASE_DIR

    blob_service_client = get_blob_service_client()
    container_client = blob_service_client.get_container_client(CONTAINER_NAME)

    blobs = container_client.list_blobs(name_starts_with=prefix)

    for blob in blobs:
        local_path = local_dir / blob.name
        download_blob(blob.name, local_path)

def upload_directory(local_dir, blob_prefix=""):
    """Upload entire directory to blob storage"""
    local_dir = Path(local_dir)

    for local_path in local_dir.rglob("*"):
        if local_path.is_file():
            # Calculate relative path
            relative_path = local_path.relative_to(local_dir)
            blob_name = f"{blob_prefix}/{relative_path}".lstrip("/")

            upload_blob(local_path, blob_name)

def main():
    """Main function with example usage"""
    import sys

    if len(sys.argv) < 2:
        print("""
Usage:
  python azure_blob_sync.py list [prefix]           - List blobs
  python azure_blob_sync.py download <blob> <local> - Download single file
  python azure_blob_sync.py upload <local> <blob>   - Upload single file
  python azure_blob_sync.py download-all [prefix]   - Download all with prefix
  python azure_blob_sync.py upload-dir <dir> [prefix] - Upload directory

Examples:
  python azure_blob_sync.py list raw/source_data
  python azure_blob_sync.py download raw/source_data/automation.csv ./automation.csv
  python azure_blob_sync.py upload ./automation.csv raw/source_data/automation.csv
  python azure_blob_sync.py download-all raw/source_data
  python azure_blob_sync.py upload-dir ./data_reviewed data_reviewed
        """)
        return

    command = sys.argv[1]

    try:
        if command == "list":
            prefix = sys.argv[2] if len(sys.argv) > 2 else ""
            list_blobs(prefix)

        elif command == "download":
            blob_name = sys.argv[2]
            local_path = Path(sys.argv[3])
            download_blob(blob_name, local_path)

        elif command == "upload":
            local_path = Path(sys.argv[2])
            blob_name = sys.argv[3]
            upload_blob(local_path, blob_name)

        elif command == "download-all":
            prefix = sys.argv[2] if len(sys.argv) > 2 else ""
            download_all(prefix)

        elif command == "upload-dir":
            local_dir = sys.argv[2]
            blob_prefix = sys.argv[3] if len(sys.argv) > 3 else ""
            upload_directory(local_dir, blob_prefix)

        else:
            print(f"Unknown command: {command}")

    except Exception as e:
        print(f"Error: {e}")
        raise

if __name__ == "__main__":
    main()
