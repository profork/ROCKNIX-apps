#!/bin/bash
# Rocknix Ungoogled Chromium Installer (aarch64) — AppImage + Chromium runtime bundle
# - Installs to /storage/Applications/ungoogled-chromium
# - Creates /storage/roms/ports/UngoogledChromium.sh
# - NO gptokeyb; touch/keyboard/mouse only
# - Forces X11 windowing (--ozone-platform-hint=x11) for widest compatibility

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/ungoogled-chromium"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.ungoogled-chromium"

APP_URL="https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/releases/download/140.0.7339.185-1/ungoogled-chromium-140.0.7339.185-1-arm64.AppImage"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/chromium-runtime.tar.gz"

APPIMAGE_PATH="${APP_DIR}/UngoogledChromium.AppImage"
RUNTIME_TGZ="${APP_DIR}/chromium-runtime.tar.gz"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"

LAUNCHER_PATH="${PORTS_DIR}/UngoogledChromium.sh"

echo "🧭 Ungoogled Chromium installer for Rocknix (aarch64)…"
sleep 1

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ This installer is for aarch64 only. Detected: $arch"
  exit 1
fi

mkdir -p "$APP_DIR" "$PORTS_DIR" "$PROFILE_DIR"
cd "$APP_DIR"

# --- Fetch AppImage ---
echo "🔽 Downloading Ungoogled Chromium AppImage…"
rm -f "$APPIMAGE_PATH"
if ! wget -O "$APPIMAGE_PATH" "$APP_URL"; then
  echo "wget failed, trying curl"
  curl -L -o "$APPIMAGE_PATH" "$APP_URL"
fi
chmod +x "$APPIMAGE_PATH"

# --- Fetch Chromium runtime bundle ---
echo "🔽 Downloading Chromium runtime bundle…"
rm -f "$RUNTIME_TGZ"
if ! wget -O "$RUNTIME_TGZ" "$RUNTIME_URL"; then
  echo "wget failed, trying curl"
  curl -L -o "$RUNTIME_TGZ" "$RUNTIME_URL"
fi

echo "📦 Extracting runtime…"
tar -xzf "$RUNTIME_TGZ" -C "$APP_DIR"

RUNTIME_DIR_FOUND="$(find "$APP_DIR" -type f -name 'libnss3.so' 2>/dev/null | head -n1 || true)"
if [ -z "$RUNTIME_DIR_FOUND" ]; then
  echo "❌ Could not locate runtime 'libnss3.so' after extraction."
  exit 1
fi
RUNTIME_DIR_FOUND="$(dirname "$RUNTIME_DIR_FOUND")/.."
rm -f "$RUNTIME_DIR_LINK"
ln -snf "$RUNTIME_DIR_FOUND" "$RUNTIME_DIR_LINK"
rm -f "$RUNTIME_TGZ"

# --- Create single Ports launcher (no gptokeyb) ---
echo "🚀 Creating UngoogledChromium launcher…"
cat > "$LAUNCHER_PATH" <<'EOF'
#!/bin/bash
set -euo pipefail

APP_DIR="/storage/Applications/ungoogled-chromium"
PROFILE_DIR="/storage/.ungoogled-chromium"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"
APPIMAGE_PATH="${APP_DIR}/UngoogledChromium.AppImage"

# Touch/KB/mouse only — no gptokeyb
trap ':' EXIT

mkdir -p "${PROFILE_DIR}/config" "${PROFILE_DIR}/home"

# Common env
export DISPLAY=:0.0
export HOME="$PROFILE_DIR"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/home"
export APPIMAGE_EXTRACT_AND_RUN=1

# Wire runtime libs/certs
export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${LD_LIBRARY_PATH-}"
export SSL_CERT_FILE="${RUNTIME_DIR_LINK}/certs/ca-certificates.crt"
export SSL_CERT_DIR="$(dirname "$SSL_CERT_FILE")"

# Flags: force X11 so things behave consistently on Rocknix
EXTRA_FLAGS="--no-sandbox --password-store=basic --enable-gamepad --force-dark-mode --ozone-platform-hint=x11"

# If GPU is flaky on some devices, you can enable software fallbacks:
# EXTRA_FLAGS="$EXTRA_FLAGS --disable-gpu --use-gl=swiftshader"

# Prefer runtime wrapper if present (sets env cleanly), else run directly
RWR="${RUNTIME_DIR_LINK}/run-with-runtime.sh"
if [ -x "$RWR" ]; then
  exec "$RWR" "$APPIMAGE_PATH" $EXTRA_FLAGS "$@"
else
  exec "$APPIMAGE_PATH" $EXTRA_FLAGS "$@"
fi
EOF
chmod +x "$LAUNCHER_PATH"

echo
echo "✅ Ungoogled Chromium installed."
echo "▶️ Launch from: $LAUNCHER_PATH"
echo "   AppImage:    $APPIMAGE_PATH"
echo "   Runtime:     $RUNTIME_DIR_LINK"
echo "ℹ️  No gamepad mapping is started (touch/keyboard/mouse only)."
