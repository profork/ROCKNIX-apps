#!/bin/bash
set -euo pipefail

# Variables
THEME_DIR="/storage/.config/emulationstation/themes"
TARGET_DIR="${THEME_DIR}/es-theme-carbon"
ZIP_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/batocera-rom-pack.zip"
ZIP_NAME="es-theme-carbon.zip"
TMP_DIR="/tmp"
EXTRACT_DIR="${TMP_DIR}/es-theme-carbon-extract"

# Prep
mkdir -p "$THEME_DIR"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

# Go to temp directory
cd "$TMP_DIR" || exit 1

# Download with wget (shows progress, saves as $ZIP_NAME)
echo "Downloading Carbon theme... Approx 150MB"
wget -q  -O "$ZIP_NAME" "$ZIP_URL"

# Extract to a throwaway folder
echo "Extracting theme..."
unzip -q -o "$ZIP_NAME" -d "$EXTRACT_DIR"

# Figure out what got extracted:
# - If there is exactly one directory at root, use that
# - Otherwise use the extract dir itself
shopt -s nullglob
roots=( "$EXTRACT_DIR"/* )
shopt -u nullglob

if [[ ${#roots[@]} -eq 1 && -d "${roots[0]}" ]]; then
  SRC_DIR="${roots[0]}"
else
  SRC_DIR="$EXTRACT_DIR"
fi

# Install (overwrite existing)
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# copy contents (including dotfiles)
shopt -s dotglob
cp -a "${SRC_DIR}/"* "$TARGET_DIR/" || true
shopt -u dotglob

# Cleanup
rm -f "$ZIP_NAME"
rm -rf "$EXTRACT_DIR"

echo "Theme installed to: $TARGET_DIR"
