#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# delete-resources.sh — Delete the resource group created by create-resources.sh
#
# Usage:
#   chmod +x scripts/delete-resources.sh
#   ./scripts/delete-resources.sh                              # default RG name
#   ./scripts/delete-resources.sh <resource-group-name>
# ---------------------------------------------------------------------------

RESOURCE_GROUP="${1:-rg-sql-vector-quickstart}"

echo "============================================================"
echo "Delete Azure Resources"
echo "============================================================"
echo "  Resource group: ${RESOURCE_GROUP}"
echo ""

read -r -p "Are you sure you want to delete '${RESOURCE_GROUP}'? [y/N] " confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Deleting resource group: ${RESOURCE_GROUP}..."
az group delete \
  --name "${RESOURCE_GROUP}" \
  --yes \
  --no-wait

echo "Resource group deletion started (runs in background)."
echo ""
echo "Note: Azure OpenAI resources are soft-deleted. To fully purge, run:"
echo "  az cognitiveservices account list-deleted --query \"[].name\" -o tsv"
echo "  az cognitiveservices account purge --name <name> --resource-group ${RESOURCE_GROUP} --location <location>"
echo ""
echo "Done."
