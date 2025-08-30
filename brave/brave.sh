#!/bin/bash
# Rocknix Brave Installer (aarch64) — AppImage + Chromium runtime bundle
# - Uses your published runtime tarball + Brave AppImage
# - Creates GPTK mapping and a launcher in /storage/roms/ports
# - Forces AppImage extract-run (no FUSE needed on Rocknix)

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/brave"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.brave"     # Brave's user-data dir
GPTK_FILE="$PORTS_DIR/brave.gptk"
BRAVE_LAUNCHER="$PORTS_DIR/Brave.sh"

BRAVE_URL="https://github.com/ivan-hc/Brave-appimage/releases/download/continuous-stable/Brave-Web-Browser-stable-1.81.137-aarch64.AppImage"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/chromium-runtime.tar.gz"

BRAVE_APPIMAGE="${APP_DIR}/Brave.AppImage"
RUNTIME_TGZ="${APP_DIR}/chromium-runtime.tar.gz"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"   # stable symlink/dir we’ll target

echo "🧭 Brave installer for Rocknix (aarch64)…"
sleep 1

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ This installer is for aarch64 only. Detected: $arch"
  exit 1
fi

mkdir -p "$APP_DIR" "$PORTS_DIR" "$PROFILE_DIR"
cd "$APP_DIR"

# --- Fetch Brave AppImage ---
echo "🔽 Downloading Brave AppImage…"
rm -f "$BRAVE_APPIMAGE"
if ! wget -O "$BRAVE_APPIMAGE" "$BRAVE_URL"; then
  echo "wget failed, trying curl"
  curl -L -o "$BRAVE_APPIMAGE" "$BRAVE_URL"
fi
chmod +x "$BRAVE_APPIMAGE"

# --- Fetch Chromium runtime bundle ---
echo "🔽 Downloading Chromium runtime bundle…"
rm -f "$RUNTIME_TGZ"
if ! wget -O "$RUNTIME_TGZ" "$RUNTIME_URL"; then
  echo "wget failed, trying curl"
  curl -L -o "$RUNTIME_TGZ" "$RUNTIME_URL"
fi


echo "📦 Extracting runtime…"
tar -xzf "$RUNTIME_TGZ" -C "$APP_DIR"

# Look for libnss3.so in extracted subfolders, using BusyBox-compatible find
RUNTIME_DIR_FOUND="$(find "$APP_DIR" -type f -name 'libnss3.so' 2>/dev/null | head -n1)"
if [ -z "$RUNTIME_DIR_FOUND" ]; then
  echo "❌ Could not locate runtime 'libnss3.so' after extraction."
  exit 1
fi

# Go up one directory level to get the "lib" dir
RUNTIME_DIR_FOUND="$(dirname "$RUNTIME_DIR_FOUND")/.."

# Normalize to a stable symlink path
rm -f "$RUNTIME_DIR_LINK"
ln -snf "$RUNTIME_DIR_FOUND" "$RUNTIME_DIR_LINK"
rm -f "$RUNTIME_TGZ"



# --- GPTK mapping (console-friendly defaults) ---
echo "🎮 Writing GPTK mapping…"
cat > "$GPTK_FILE" <<'EOF'
up = up
down = down
left = left
right = right
a = enter
b = esc
x = ctrl+w
y = ctrl+t
start = enter
select = esc
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# --- Launcher ---
echo "🚀 Creating Brave launcher…"
cat > "$BRAVE_LAUNCHER" <<EOF
#!/bin/bash
trap 'pkill gptokeyb' EXIT

export DISPLAY=:0.0
export HOME="$PROFILE_DIR"

# Point Chromium/Electron to the bundled NSS/NSPR + CA certs
export LD_LIBRARY_PATH="$RUNTIME_DIR_LINK/lib:\${LD_LIBRARY_PATH}"
export SSL_CERT_FILE="$RUNTIME_DIR_LINK/certs/ca-certificates.crt"
export SSL_CERT_DIR="\$(dirname "\$SSL_CERT_FILE")"

# Rocknix rootfs is nosuid: skip FUSE to avoid the fusermount warning
export APPIMAGE_EXTRACT_AND_RUN=1

# Tame DBus/keyring noise on appliance images
EXTRA_FLAGS="--no-sandbox --password-store=basic"

# Optional GPU flags: start safe; tune later if you wire up Mali/GBM properly
# EXTRA_FLAGS="\$EXTRA_FLAGS --disable-gpu --use-gl=swiftshader"

gptokeyb -p "Brave" -c "$GPTK_FILE" -k brave &>/dev/null &
sleep 1

exec "$BRAVE_APPIMAGE" \$EXTRA_FLAGS "\$@"
EOF
chmod +x "$BRAVE_LAUNCHER"

echo
echo "✅ Brave installed."
echo "▶️ Launch from: $BRAVE_LAUNCHER"
echo "   (Uses runtime at: $RUNTIME_DIR_LINK)"
echo "🎮 Exit with Start+Select"
