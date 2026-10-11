#!/usr/bin/env bash
set -euo pipefail

# GitOps Administrator Lab - Azure Bootstrap
# Creates temporary Azure resources for Terraform remote state.

# Azure configuration
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

EXPECTED_SUBSCRIPTION="fedbb0dc-4bcb-4f61-b33e-ef6df50bac75"

if [[ "$SUBSCRIPTION_ID" != "$EXPECTED_SUBSCRIPTION" ]]; then
  echo "ERROR: Incorrect Azure subscription."
  exit 1
fi

LOCATION="eastus"
BOOTSTRAP_RG="rg-gitops-bootstrap"
STORAGE_ACCOUNT="stgitopsadmin${SUBSCRIPTION_ID:0:8}"
CONTAINER_NAME="tfstate"

echo "===================================="
echo "GitOps Admin - Azure Bootstrap"
echo "===================================="

echo "Subscription: $SUBSCRIPTION_ID"
echo "Tenant:       $TENANT_ID"
echo "Region:       $LOCATION"
echo "Resource Group: $BOOTSTRAP_RG"
echo "Storage Account: $STORAGE_ACCOUNT"

# Verify Azure CLI authentication
az account show --output none

echo "Azure authentication verified."

# Resource creation will be added after review.

# Create Terraform backend Resource Group
echo "Creating Terraform backend Resource Group..."

az group create \
  --name "$BOOTSTRAP_RG" \
  --location "$LOCATION" \
  --tags project=gitops-admin-lab purpose=terraform-backend \
  --output none

# Create Azure Storage Account
echo "Creating Terraform backend Storage Account..."

az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$BOOTSTRAP_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none

# Create Terraform state blob container using Entra authentication
echo "Creating Terraform state container..."

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --output none

echo "Terraform backend bootstrap completed."
