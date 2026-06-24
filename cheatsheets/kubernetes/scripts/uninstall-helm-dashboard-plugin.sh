#!/bin/bash

# Helm Dashboard Plugin Uninstallation Script
# This script removes the Helm Dashboard plugin
# https://github.com/komodorio/helm-dashboard

set -e

echo "🗑️  Uninstalling Helm Dashboard Plugin..."

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: Helm is not installed."
    exit 1
fi

# Check if the plugin is installed
if helm plugin list | grep -q "dashboard"; then
    echo "🔄 Removing Helm Dashboard plugin..."
    helm plugin uninstall dashboard
    echo "✅ Helm Dashboard plugin uninstalled successfully!"
else
    echo "⚠️  Helm Dashboard plugin is not installed."
fi

echo ""
echo "🎉 Cleanup completed!"
