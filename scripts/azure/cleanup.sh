#!/usr/bin/env bash
set -euo pipefail

# GitOps Administrator Lab - Azure Cleanup

EXPECTED_SUBSCRIPTION="fedbb0dc-4bcb-4f61-b33e-ef6df50bac75"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

BOOTSTRAP_RG="rg-gitops-bootstrap"
LAB_RG="rg-gitops-admin-dev"
STORAGE_ACCOUNT="stgitopsadmin${SUBSCRIPTION_ID:0:8}"

MODE="${1:---dry-run}"

echo "===================================="
echo "GitOps Admin - Azure Cleanup"
echo "===================================="

echo "Subscription: $SUBSCRIPTION_ID"
echo "Terraform Backend RG: $BOOTSTRAP_RG"
echo "Application RG: $LAB_RG"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Mode: $MODE"

# Safety check: correct Azure subscription
if [[ "$SUBSCRIPTION_ID" != "$EXPECTED_SUBSCRIPTION" ]]; then
  echo "ERROR: Incorrect Azure subscription."
  exit 1
fi

# Check resource groups
echo ""
echo "Checking Azure lab resources..."

for RG in "$LAB_RG" "$BOOTSTRAP_RG"; do
  if [[ "$(az group exists --name "$RG")" == "true" ]]; then
    echo "FOUND: $RG"
  else
    echo "NOT FOUND: $RG"
  fi
done

case "$MODE" in
  --dry-run)
    echo ""
    echo "DRY RUN ONLY - No resources deleted."
    ;;

  --delete-backend)
    # Terraform-managed resources must be destroyed first.
    if [[ "$(az group exists --name "$LAB_RG")" == "true" ]]; then
      echo "ERROR: Application RG still exists."
      echo "Run Terraform destroy successfully before deleting backend."
      exit 1
    fi

    if [[ "$(az group exists --name "$BOOTSTRAP_RG")" != "true" ]]; then
      echo "Backend resource group does not exist."
      exit 0
    fi

    echo ""
    echo "WARNING: This will delete the Terraform backend and state."
    read -r -p "Type DELETE-BACKEND to confirm: " CONFIRM

    if [[ "$CONFIRM" != "DELETE-BACKEND" ]]; then
      echo "Cleanup cancelled."
      exit 1
    fi

    az group delete \
      --name "$BOOTSTRAP_RG" \
      --yes \
      --no-wait

    echo "Backend resource group deletion requested."
    echo "Deletion is asynchronous; verify completion before ending the session."
    ;;

  *)
    echo "ERROR: Invalid mode: $MODE"
    echo "Usage: $0 [--dry-run|--delete-backend]"
    exit 1
    ;;
esac
