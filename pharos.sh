#!/bin/sh
set -e

ZIP_URL="https://github.com/JeodC/Pharos/archive/refs/heads/main.zip"
PORTS_DIR="/storage/roms/ports"
TMP_DIR="/tmp/pharos_dl"
ZIP_FILE="$TMP_DIR/pharos-main.zip"

mkdir -p "$PORTS_DIR" "$TMP_DIR"

echo "▶ Downloading Pharos..."
if command -v curl >/dev/null 2>&1; then
    curl -L "$ZIP_URL" -o "$ZIP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$ZIP_FILE" "$ZIP_URL"
else
    echo "❌ Neither curl nor wget found."
    exit 1
fi

echo "▶ Extracting..."
rm -rf "$TMP_DIR/Pharos-main" "$TMP_DIR"/Pharos-main-*
if command -v unzip >/dev/null 2>&1; then
    unzip -o "$ZIP_FILE" -d "$TMP_DIR" >/dev/null
else
    # try busybox unzip if available
    if busybox unzip >/dev/null 2>&1; then
        busybox unzip -o "$ZIP_FILE" -d "$TMP_DIR" >/dev/null
    else
        echo "❌ unzip not found (regular or busybox)."
        exit 1
    fi
fi

# GitHub usually extracts to Pharos-main/
SRC_DIR=""
if [ -d "$TMP_DIR/Pharos-main" ]; then
    SRC_DIR="$TMP_DIR/Pharos-main"
else
    # Fallback in case the folder name changes slightly
    SRC_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name 'Pharos-main*' | head -n 1)"
fi

if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
    echo "❌ Could not locate extracted Pharos directory."
    exit 1
fi

if [ ! -f "$SRC_DIR/Pharos App.sh" ]; then
    echo "❌ 'Pharos App.sh' not found in extracted archive."
    exit 1
fi

if [ ! -d "$SRC_DIR/Pharos" ]; then
    echo "❌ 'Pharos' folder not found in extracted archive."
    exit 1
fi

echo "▶ Installing to $PORTS_DIR..."
cp -f "$SRC_DIR/Pharos App.sh" "$PORTS_DIR/"
chmod +x "$PORTS_DIR/Pharos App.sh"

# Copy (or update) the Pharos folder
rm -rf "$PORTS_DIR/Pharos"
cp -R "$SRC_DIR/Pharos" "$PORTS_DIR/"

echo "✅ Pharos installed."
echo "   Script:  $PORTS_DIR/Pharos App.sh"
echo "   Folder:  $PORTS_DIR/Pharos"
echo "   Launch it from Ports."
