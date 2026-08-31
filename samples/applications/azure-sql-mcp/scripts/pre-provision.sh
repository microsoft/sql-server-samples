#!/usr/bin/env bash
# pre-provision.sh — Auto-detect deployer login and public IP before provisioning.

set -euo pipefail

# Auto-detect deployer login (email) if not already set
CURRENT_LOGIN=$(azd env get-value AZURE_DEPLOYER_LOGIN 2>/dev/null || true)
if [ -z "$CURRENT_LOGIN" ]; then
    echo "Detecting deployer login from Azure CLI..."
    LOGIN=$(az account show --query user.name -o tsv)
    if [ -n "$LOGIN" ]; then
        azd env set AZURE_DEPLOYER_LOGIN "$LOGIN"
        echo "  Set AZURE_DEPLOYER_LOGIN=$LOGIN"
    else
        echo "ERROR: Could not detect login. Run: azd env set AZURE_DEPLOYER_LOGIN your-email@example.com"
        exit 1
    fi
fi

# Auto-detect deployer public IP for SQL firewall
CURRENT_IP=$(azd env get-value AZURE_DEPLOYER_IP 2>/dev/null || true)
if [ -z "$CURRENT_IP" ]; then
    echo "Detecting deployer public IP..."
    IP=$(curl -s --max-time 10 https://api.ipify.org || true)
    if [ -n "$IP" ]; then
        azd env set AZURE_DEPLOYER_IP "$IP"
        echo "  Set AZURE_DEPLOYER_IP=$IP"
    else
        echo "WARNING: Could not detect public IP. SQL post-provision scripts may fail."
        azd env set AZURE_DEPLOYER_IP ""
    fi
fi
