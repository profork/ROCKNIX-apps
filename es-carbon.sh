#!/bin/bash

# Variables
THEME_DIR="/storage/.config/emulationstation/themes"
ZIP_URL="https://github.com/fabricecaruso/es-theme-carbon/archive/refs/heads/master.zip"
ZIP_NAME="master.zip"
TMP_DIR="/tmp"

# Go to temp directory
cd "$TMP_DIR" || exit 1

# Download with wget (shows progress, saves as $ZIP_NAME)
echo "Downloading Carbon theme...Appox 150Mb"
wget -q --show-progress -O "$ZIP_NAME" "$ZIP_URL"

# Extract
echo "Extracting theme..."
unzip -q "$ZIP_NAME"

# Move to themes directory
mkdir -p "$THEME_DIR"
mv -f es-theme-carbon-master "$THEME_DIR/"

# Cleanup
rm -f "$ZIP_NAME"

echo "Theme installed to: $THEME_DIR/es-theme-carbon-master"
