#!/bin/bash
set -e

URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/es-music.zip"
DEST_DIR="/storage/roms/music"
TMP_FILE="/tmp/es-music.zip"

# Create destination if missing
mkdir -p "$DEST_DIR"

echo "⬇️ Downloading es-music.zip..."
curl -L "$URL" -o "$TMP_FILE"

echo "📂 Extracting to $DEST_DIR..."
unzip -o "$TMP_FILE" -d "$DEST_DIR"

echo "✅ Done. Files extracted to $DEST_DIR"
