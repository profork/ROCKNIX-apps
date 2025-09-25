#!/bin/bash
# Rocknix Greenlight Installer (aarch64) — v233, NO GPTOKEYB
# - Installs to /storage/Applications/greenlight
# - Creates /storage/roms/ports/Greenlight.sh (touch/KB/mouse only)
# - Forces Chromium runtime via run-with-runtime.sh

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/greenlight"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.greenlight"

APPTGZ_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/greenlight-233.aarch64.tar.gz"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/chromium-runtime.tar.gz"

APPTGZ_PATH="${APP_DIR}/greenlight.tar.gz"
RUNTIME_TGZ="${APP_DIR}/chromium-runtime.tar.gz"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"

GREENLIGHT_LAUNCHER="${PORTS_DIR}/Greenlight.sh"

echo "🧭 Greenlight v233 installer (no gptokeyb)…"

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ aarch64 only. Detected: $arch"
  exit 1
fi

mkdir -p "$APP_DIR" "$PORTS_DIR" "$PROFILE_DIR"
cd "$APP_DIR"

# --- Fetch payload ---
echo "🔽 Downloading Greenlight v233…"
rm -f "$APPTGZ_PATH"
wget -O "$APPTGZ_PATH" "$APPTGZ_URL" || curl -L -o "$APPTGZ_PATH" "$APPTGZ_URL"

echo "📦 Extracting app…"
rm -rf "${APP_DIR}/greenlight"
mkdir -p "${APP_DIR}/greenlight"
tar -xzf "$APPTGZ_PATH" -C "${APP_DIR}/greenlight"
rm -f "$APPTGZ_PATH"

# --- Fetch Chromium runtime ---
echo "🔽 Downloading Chromium runtime bundle…"
rm -f "$RUNTIME_TGZ"
wget -O "$RUNTIME_TGZ" "$RUNTIME_URL" || curl -L -o "$RUNTIME_TGZ" "$RUNTIME_URL"

echo "📦 Extracting runtime…"
tar -xzf "$RUNTIME_TGZ" -C "$APP_DIR"
rm -f "$RUNTIME_TGZ"

RUNTIME_DIR_FOUND="$(find "$APP_DIR" -type f -name 'libnss3.so' 2>/dev/null | head -n1 || true)"
if [ -z "$RUNTIME_DIR_FOUND" ]; then
  echo "❌ Could not locate runtime 'libnss3.so' after extraction."
  exit 1
fi
RUNTIME_DIR_FOUND="$(dirname "$RUNTIME_DIR_FOUND")/.."
ln -snf "$RUNTIME_DIR_FOUND" "$RUNTIME_DIR_LINK"

# --- Ensure binaries are executable ---
find "${APP_DIR}/greenlight" -maxdepth 3 -type f \
  \( -name 'greenlight*' -o -name 'chrome*' -o -name 'run.sh' \) \
  ! -name '*crashpad*' -exec chmod +x {} \; 2>/dev/null || true

# --- Create launcher (NO gptokeyb) ---
cat > "$GREENLIGHT_LAUNCHER" <<'EOF'
#!/bin/bash
set -euo pipefail

APP_DIR="/storage/Applications/greenlight"
PROFILE_DIR="/storage/.greenlight"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"

# Touch/KB/mouse only — no gptokeyb
trap ':' EXIT

mkdir -p "${PROFILE_DIR}/config" "${PROFILE_DIR}/home"

# Find the real Greenlight binary (avoid crashpad helper)
GREENLIGHT_BIN="$(find "${APP_DIR}/greenlight" -maxdepth 3 -type f -name 'greenlight*' ! -name '*crashpad*' | head -n1 || true)"
if [ -z "$GREENLIGHT_BIN" ]; then
  echo "❌ Greenlight binary not found"; exit 1
fi
chmod +x "$GREENLIGHT_BIN" || true

# Sanity: runtime libs present
[ -f "${RUNTIME_DIR_LINK}/lib/libnss3.so" ] || { echo "❌ Missing ${RUNTIME_DIR_LINK}/lib/libnss3.so"; exit 1; }

# Chromium/Electron flags (add touch helpers if needed)
EXTRA_FLAGS="--no-sandbox --enable-gamepad --password-store=basic --force-dark-mode --touch-events=enabled"

# Prefer runtime wrapper to enforce LD paths & certs
RWR="${RUNTIME_DIR_LINK}/run-with-runtime.sh"
if [ -x "$RWR" ]; then
  exec "$RWR" "$GREENLIGHT_BIN" $EXTRA_FLAGS "$@"
else
  # Fallback: export env explicitly
  export DISPLAY=:0.0
  export HOME="$PROFILE_DIR"
  export XDG_CONFIG_HOME="$HOME/config"
  export XDG_DATA_HOME="$HOME/home"
  export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${APP_DIR}/greenlight:${APP_DIR}/greenlight/lib:${LD_LIBRARY_PATH-}"
  export SSL_CERT_FILE="${RUNTIME_DIR_LINK}/certs/ca-certificates.crt"
  export SSL_CERT_DIR="$(dirname "$SSL_CERT_FILE")"
  exec "$GREENLIGHT_BIN" $EXTRA_FLAGS "$@"
fi
EOF

chmod +x "$GREENLIGHT_LAUNCHER"

echo
echo "✅ Greenlight 2.3.3 installed."
echo "▶️ Launch from: $GREENLIGHT_LAUNCHER"
echo "   Runtime:     $RUNTIME_DIR_LINK"
echo "ℹ️  Tip: exit via touchscreen (xbox logo in app."
