#!/bin/sh

set -e

# Config
SOAR_DIR="$HOME/soar"
SOAR_BIN="$SOAR_DIR/soar"
BIN_WRAPPER="$HOME/bin"
PROFILE="$HOME/.profile"

echo "🪂 Installing Soar to $SOAR_DIR..."

# Create install dir
mkdir -p "$SOAR_DIR"
cd "$SOAR_DIR"

# Download Soar binary
SOAR_URL="https://github.com/pkgforge/soar/releases/download/v0.6.5/soar-aarch64-linux"
FILENAME="soar-aarch64-linux"

echo "⬇️  Downloading Soar from $SOAR_URL..."
curl -L -o soar "$SOAR_URL"
chmod +x soar

# Create symlink in ~/bin
echo "🔗 Creating symlink in $BIN_WRAPPER..."
mkdir -p "$BIN_WRAPPER"
ln -sf "$SOAR_BIN" "$BIN_WRAPPER/soar"

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
echo "✅ Soar installed to: $SOAR_BIN"
echo "✅ Symlinked as: $BIN_WRAPPER/soar"
echo "✅ PATH updated in: $PROFILE and loaded now"
echo "Reboot then..."
echo "🚀 Try it out: run 👉 soar help after running new shell session"
