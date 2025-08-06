#!/bin/bash
# Downloads and runs the arch-kodi.sh installer from GitHub

set -euo pipefail

# Vars
RI_DIR="/storage/ri"
SCRIPT_URL="https://github.com/profork/ROCKNIX-apps/raw/main/kodi/arch-kodi.sh"
SCRIPT_PATH="$RI_DIR/arch-kodi.sh"

echo "➤ Creating working directory: $RI_DIR"
mkdir -p "$RI_DIR"

echo "➤ Downloading arch-kodi.sh..."
curl -L -o "$SCRIPT_PATH" "$SCRIPT_URL"

echo "➤ Making script executable..."
chmod +x "$SCRIPT_PATH"

echo "➤ Running Kodi installer..."
"$SCRIPT_PATH"

# Optional cleanup:
# echo "➤ Cleaning up..."
# rm -f "$SCRIPT_PATH"

echo "✅ Done!"
