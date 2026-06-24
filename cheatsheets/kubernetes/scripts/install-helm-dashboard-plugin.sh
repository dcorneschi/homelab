#!/bin/bash

# Helm Dashboard Plugin Installation Script
# This script installs the Helm Dashboard as a Helm plugin
# https://github.com/komodorio/helm-dashboard

set -e

echo "🔌 Installing Helm Dashboard as a Plugin..."

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if the plugin is already installed
if helm plugin list | grep -q "dashboard"; then
    echo "⚠️  Helm Dashboard plugin is already installed."
    read -p "🤔 Do you want to update it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Updating Helm Dashboard plugin..."
        helm plugin update dashboard
        echo "✅ Plugin updated successfully!"
    else
        echo "📦 Keeping existing plugin installation."
        exit 0
    fi
else
    echo "📦 Installing Helm Dashboard plugin..."
    helm plugin install https://github.com/komodorio/helm-dashboard.git
    echo "✅ Plugin installed successfully!"
fi

echo ""
echo "🚀 Helm Dashboard Plugin is ready!"
echo ""
echo "🌐 To start the dashboard:"
echo "   helm dashboard"
echo ""
echo "🔧 Additional options:"
echo "   helm dashboard --help                    # Show help"
echo "   helm dashboard --port 8080               # Specify port (default: 8080)"
echo "   helm dashboard --bind 0.0.0.0            # Bind to all interfaces"
echo "   helm dashboard --no-browser              # Don't open browser automatically"
echo "   helm dashboard --namespace <namespace>   # Focus on specific namespace"
echo ""
echo "📋 The dashboard will automatically open in your browser at http://localhost:8080"
echo ""
echo "🔧 To uninstall the plugin, run: ./uninstall-helm-dashboard-plugin.sh"
