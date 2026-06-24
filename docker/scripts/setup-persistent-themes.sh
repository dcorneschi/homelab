#!/bin/bash

# Setup persistent Gitea themes that survive container recreation
# This script downloads themes to a local directory and sets up volume mounting

set -e

THEMES_DIR="./themes"
BASE_URL="https://git.sainnhe.dev/sainnhe/gitea-themes/raw/branch/master/dist"

# List of all available themes (confirmed from repository)
THEMES=(
    "edge-dark"
    "edge-light" 
    "edge-auto"
    "everforest-dark"
    "everforest-light"
    "everforest-auto"
    "gruvbox-dark"
    "gruvbox-light"
    "gruvbox-auto"
    "gruvbox-material-dark"
    "gruvbox-material-light"
    "gruvbox-material-auto"
    "nord"
    "palenight"
    "soft-era"
    "sonokai"
    "sonokai-andromeda"
    "sonokai-atlantis"
    "sonokai-espresso"
    "sonokai-maia"
    "sonokai-shusia"
)

# Function to test if a theme exists
test_theme_exists() {
    local theme=$1
    local url="${BASE_URL}/theme-${theme}.css"
    
    if curl -f -s -I "$url" >/dev/null 2>&1; then
        return 0  # exists
    else
        return 1  # doesn't exist
    fi
}

echo "🎨 Setting up persistent Gitea themes..."

# Create themes directory
mkdir -p "$THEMES_DIR"

# Download each theme
echo "📥 Downloading themes from ${BASE_URL}..."
for theme in "${THEMES[@]}"; do
    if [ ! -f "${THEMES_DIR}/theme-${theme}.css" ]; then
        echo "  Downloading: theme-${theme}.css"
        if curl -fsSL "${BASE_URL}/theme-${theme}.css" -o "${THEMES_DIR}/theme-${theme}.css"; then
            echo "    ✅ Downloaded successfully"
        else
            echo "    ❌ Download failed"
        fi
    else
        echo "  ✅ Already exists: theme-${theme}.css"
    fi
done

# Set proper permissions
chmod -R 755 "$THEMES_DIR"

echo ""
echo "✅ Persistent themes setup complete!"
echo "📁 Themes directory: ${THEMES_DIR}/"
echo ""
echo "📝 Next steps:"
echo "1. Add this volume mount to your docker-compose.yml:"
echo "   volumes:"
echo "     - ./themes:/data/gitea/public/assets/css"
echo ""
echo "2. Add themes to your Gitea environment variables:"
echo "   - GITEA__ui__THEMES=gitea,arc-green,$(IFS=,; echo "${THEMES[*]}")"
echo ""
echo "3. Restart/recreate your containers:"
echo "   docker compose up -d --force-recreate"
echo ""
echo "🔄 Themes will now persist across container recreation!"
