#!/bin/sh

set -e

# Config
PKGX_DIR="$HOME/pkgx"
PKGX_BIN="$PKGX_DIR/pkgx"
BIN_WRAPPER="$HOME/bin"
PROFILE="$HOME/.profile"

echo "📦 Installing pkgx to $PKGX_DIR..."

# Create install dir
mkdir -p "$PKGX_DIR"
cd "$PKGX_DIR"

# Fetch latest aarch64 build URL using jq
echo "🔍 Fetching latest pkgx release URL..."
PKGX_URL=$(curl -s https://api.github.com/repos/pkgxdev/pkgx/releases/latest \
  | jq -r '.assets[] | select(.name | endswith("+linux+aarch64.tar.gz")) | .browser_download_url')

if [ -z "$PKGX_URL" ]; then
  echo "❌ Could not find pkgx aarch64 build. Exiting."
  exit 1
fi

FILENAME=$(basename "$PKGX_URL")

# Download & extract
echo "⬇️  Downloading $FILENAME..."
curl -LO "$PKGX_URL"
tar -xzf "$FILENAME"
chmod +x pkgx

# Link to ~/bin
echo "🔗 Creating symlink in $BIN_WRAPPER..."
mkdir -p "$BIN_WRAPPER"
ln -sf "$PKGX_BIN" "$BIN_WRAPPER/pkgx"

# Add to ~/.profile if not already present
if [ ! -f "$PROFILE" ]; then
  touch "$PROFILE"
fi

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$PROFILE"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$PROFILE"
  echo "📄 Added PATH update to $PROFILE"
fi

# Apply PATH immediately in current shell
export PATH="$HOME/bin:$PATH"
. "$PROFILE"

# Done
echo
echo "✅ pkgx installed to: $PKGX_BIN"
echo "✅ Symlinked as: $BIN_WRAPPER/pkgx"
echo "✅ PATH updated in: $PROFILE and loaded now"
echo
echo "🚀 Try something fun: run 👉 pkgx fastfetch"

