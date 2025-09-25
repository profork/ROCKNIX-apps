#!/bin/bash
# Rocknix — OUI installer/runner

set -euo pipefail

TMP_DIR="/storage/tmp/oui.$$"
ZIP_URL="https://github.com/profork/ROCKNIX-apps/raw/main/pygame/oui.zip"
ZIP_PATH="$TMP_DIR/oui.zip"

mkdir -p "$TMP_DIR"

# --- download helper ---
fetch() {
  local url="$1" out="$2"
  if command -v curl >/dev/null; then
    curl -L --fail --retry 3 -o "$out" "$url"
  elif command -v wget >/dev/null; then
    wget -O "$out" "$url"
  else
    echo "Need curl or wget"
    exit 1
  fi
}

echo "📥 Downloading oui.zip…"
fetch "$ZIP_URL" "$ZIP_PATH"

# --- unzip (password required) ---
echo "🔑 Please enter the password to extract oui.zip:"
if command -v unzip >/dev/null; then
  unzip "$ZIP_PATH" -d "$TMP_DIR"
elif command -v bsdtar >/dev/null; then
  bsdtar -xf "$ZIP_PATH" -C "$TMP_DIR"
elif busybox unzip -v >/dev/null 2>&1; then
  busybox unzip "$ZIP_PATH" -d "$TMP_DIR"
else
  echo "Need unzip/bsdtar/busybox unzip"
  exit 1
fi

# --- run oui.sh ---
if [ -f "$TMP_DIR/oui.sh" ]; then
  chmod +x "$TMP_DIR/oui.sh"
  echo "▶ Running oui.sh…"
  bash "$TMP_DIR/oui.sh"
else
  echo "❌ Could not find oui.sh inside archive"
  exit 1
fi
