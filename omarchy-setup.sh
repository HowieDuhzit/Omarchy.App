#!/bin/bash

# Omarchy Installer Setup Script
# This script automatically downloads and installs the Omarchy protocol handler

set -e  # Exit on any error

echo "🚀 Omarchy Installer Setup"
echo "=========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub repository URLs
GITHUB_BASE="https://raw.githubusercontent.com/HowieDuhzit/omarchy/refs/heads/ChromiumWebAppInstaller"
INSTALL_HANDLER_URL="$GITHUB_BASE/bin/omarchy-install-handler"
DESKTOP_FILE_URL="$GITHUB_BASE/applications/omarchy-install-handler.desktop"

# Local directories
LOCAL_BIN="$HOME/.local/share/omarchy/bin"
LOCAL_APPS="$HOME/.local/share/applications"
LOCAL_MIME="$HOME/.local/share/mime/packages"

echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p "$LOCAL_BIN" "$LOCAL_APPS" "$LOCAL_MIME"

echo -e "${BLUE}📥 Downloading omarchy-install-handler...${NC}"
if command -v curl >/dev/null 2>&1; then
    curl -s "$INSTALL_HANDLER_URL" -o "$LOCAL_BIN/omarchy-install-handler"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$INSTALL_HANDLER_URL" -O "$LOCAL_BIN/omarchy-install-handler"
else
    echo -e "${RED}❌ Error: Neither curl nor wget found. Please install one of them.${NC}"
    exit 1
fi

echo -e "${BLUE}📥 Downloading omarchy-install-handler.desktop...${NC}"
if command -v curl >/dev/null 2>&1; then
    curl -s "$DESKTOP_FILE_URL" -o "$LOCAL_APPS/omarchy-install-handler.desktop"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$DESKTOP_FILE_URL" -O "$LOCAL_APPS/omarchy-install-handler.desktop"
else
    echo -e "${RED}❌ Error: Neither curl nor wget found. Please install one of them.${NC}"
    exit 1
fi

echo -e "${BLUE}🔧 Setting permissions...${NC}"
chmod +x "$LOCAL_BIN/omarchy-install-handler"

echo -e "${BLUE}📝 Creating mimetype configuration...${NC}"
cat > "$LOCAL_MIME/omarchy.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="x-scheme-handler/omarchy">
    <comment>Omarchy Web App Installer</comment>
    <glob pattern="omarchy:*"/>
  </mime-type>
</mime-info>
EOF

echo -e "${BLUE}🔗 Registering protocol handler...${NC}"
xdg-mime default omarchy-install-handler.desktop x-scheme-handler/omarchy

echo -e "${BLUE}🔄 Updating desktop database...${NC}"
update-desktop-database "$LOCAL_APPS" 2>/dev/null || true
update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "${YELLOW}📋 What was installed:${NC}"
echo "   • omarchy-install-handler → $LOCAL_BIN/"
echo "   • omarchy-install-handler.desktop → $LOCAL_APPS/"
echo "   • omarchy.xml → $LOCAL_MIME/"
echo ""
echo -e "${YELLOW}🎯 How to test:${NC}"
echo "   1. Open a web browser"
echo "   2. Navigate to an Omarchy app directory"
echo "   3. Click the install button on any app"
echo "   4. The omarchy:// protocol should launch the installer"
echo ""
echo -e "${GREEN}🎉 Ready to install Omarchy web apps!${NC}"
