#!/bin/bash
# Rocknix GeForce Infinity Installer (aarch64)
# - Installs to /storage/Applications/geforceinfinity
# - Creates /storage/roms/ports/GeForceInfinity.sh
# - Forces Chromium runtime via run-with-runtime.sh
# - gptokeyb: Start+Select -> Alt+F4 (scoped to "geforceinfinity")
# - Render modes: mesa (default), angle, swift, gpuoff

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/geforceinfinity"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.geforceinfinity"

APPTGZ_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/geforce-infinity.aarch64.tar.gz"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/chromium-runtime.tar.gz"

APPTGZ_PATH="${APP_DIR}/geforce-infinity.tar.gz"
RUNTIME_TGZ="${APP_DIR}/chromium-runtime.tar.gz"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"

HOTKEY_GPTK="${PORTS_DIR}/geforceinfinity_hotkey.gptk"
LAUNCHER_PATH="${PORTS_DIR}/GeForceInfinity.sh"

echo "🧭 GeForce Infinity (aarch64) installer…"

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ aarch64 only. Detected: $arch"
  exit 1
fi

mkdir -p "$APP_DIR" "$PORTS_DIR" "$PROFILE_DIR"
cd "$APP_DIR"

# --- Fetch payload ---
echo "🔽 Downloading app…"
rm -f "$APPTGZ_PATH"
wget -O "$APPTGZ_PATH" "$APPTGZ_URL" || curl -L -o "$APPTGZ_PATH" "$APPTGZ_URL"

echo "📦 Extracting app…"
rm -rf "${APP_DIR}/geforceinfinity"
mkdir -p "${APP_DIR}/geforceinfinity"
tar -xzf "$APPTGZ_PATH" -C "${APP_DIR}/geforceinfinity"
rm -f "$APPTGZ_PATH"

# Ensure executables are +x
find "${APP_DIR}/geforceinfinity" -maxdepth 3 -type f \
  \( -name 'geforce-*' -o -name 'chrome*' -o -name 'run.sh' \) \
  ! -name '*crashpad*' -exec chmod +x {} \; 2>/dev/null || true

# --- Fetch Chromium runtime ---
echo "🔽 Downloading Chromium runtime…"
rm -f "$RUNTIME_TGZ"
wget -O "$RUNTIME_TGZ" "$RUNTIME_URL" || curl -L -o "$RUNTIME_TGZ" "$RUNTIME_URL"

echo "📦 Extracting runtime…"
tar -xzf "$RUNTIME_TGZ" -C "$APP_DIR"
rm -f "$RUNTIME_TGZ"

# Symlink to runtime root (detect via libnss3.so)
RUNTIME_DIR_FOUND="$(find "$APP_DIR" -type f -name 'libnss3.so' | head -n1 || true)"
if [ -z "$RUNTIME_DIR_FOUND" ]; then
  echo "❌ runtime libnss3.so not found"
  exit 1
fi
RUNTIME_DIR_FOUND="$(dirname "$RUNTIME_DIR_FOUND")/.."
ln -snf "$RUNTIME_DIR_FOUND" "$RUNTIME_DIR_LINK"

# --- Hotkey-only GPTK map ---
cat > "$HOTKEY_GPTK" <<'EOF'
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# --- Ports launcher (runtime wrapper + render modes + gptokeyb Alt+F4) ---
cat > "$LAUNCHER_PATH" <<'EOF'
#!/bin/bash
set -euo pipefail

APP_DIR="/storage/Applications/geforceinfinity"
PROFILE_DIR="/storage/.geforceinfinity"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"
HOTKEY_GPTK="/storage/roms/ports/geforceinfinity_hotkey.gptk"

# Modes: mesa (default), angle, swift, gpuoff  — set RENDER_MODE=... before launching if you want
RENDER_MODE="${RENDER_MODE:-mesa}"

# Clean up mapping on exit (mirrors your LibreWolf pattern)
trap 'pkill gptokeyb || true' EXIT

mkdir -p "${PROFILE_DIR}/config" "${PROFILE_DIR}/home"

# Find the real app binary (avoid crashpad helper)
BIN="$(find "${APP_DIR}/geforceinfinity" -maxdepth 3 -type f -name 'geforce-infinity' ! -name '*crashpad*' | head -n1 || true)"
if [ -z "$BIN" ]; then
  BIN="$(find "${APP_DIR}/geforceinfinity" -maxdepth 3 -type f -name 'geforce*' ! -name '*crashpad*' | head -n1 || true)"
fi
[ -n "$BIN" ] || { echo "❌ GeForce Infinity binary not found"; exit 1; }
chmod +x "$BIN" || true

# Sanity: runtime libs present?
[ -f "${RUNTIME_DIR_LINK}/lib/libnss3.so" ] || { echo "❌ Missing ${RUNTIME_DIR_LINK}/lib/libnss3.so"; exit 1; }

# Start HOTKEY-ONLY mapping, scoped to the process/window name you pkill successfully
if command -v gptokeyb >/dev/null 2>&1; then
  \gptokeyb -p "geforceinfinity" -c "$HOTKEY_GPTK" -k geforceinfinity &>/dev/null &
  sleep 1
fi

# Common Electron flags
COMMON="--no-sandbox --enable-gamepad --password-store=basic --force-dark-mode --ozone-platform-hint=x11"

# Render-mode specific env/flags
case "$RENDER_MODE" in
  mesa)
    # Use system Mesa EGL/GL; disable Vulkan; avoid app's libEGL/libGLES
    export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${LD_LIBRARY_PATH-}"
    EXTRA="--disable-features=Vulkan --use-gl=egl --use-angle=gl"
    ;;
  angle)
    # Use app's ANGLE libs but still disable Vulkan
    export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${APP_DIR}/geforceinfinity:${APP_DIR}/geforceinfinity/lib:${LD_LIBRARY_PATH-}"
    EXTRA="--disable-features=Vulkan --use-gl=angle --use-angle=gl"
    ;;
  swift)
    # Software rendering via SwiftShader
    export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${LD_LIBRARY_PATH-}"
    export VK_ICD_FILENAMES="${APP_DIR}/geforceinfinity/vk_swiftshader_icd.json:${RUNTIME_DIR_LINK}/lib/vk_swiftshader_icd.json"
    export LIBGL_ALWAYS_SOFTWARE=1
    EXTRA="--use-gl=angle --use-angle=swiftshader --disable-features=Vulkan"
    ;;
  gpuoff)
    # Hard disable GPU entirely
    export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${LD_LIBRARY_PATH-}"
    EXTRA="--disable-gpu --use-gl=swiftshader --use-angle=swiftshader"
    ;;
  *)
    echo "Unknown RENDER_MODE='$RENDER_MODE' (use mesa|angle|swift|gpuoff)"; exit 1;;
esac

# Prefer runtime wrapper to enforce NSS/certs and keep env clean
RWR="${RUNTIME_DIR_LINK}/run-with-runtime.sh"
if [ -x "$RWR" ]; then
  exec "$RWR" "$BIN" $COMMON $EXTRA "$@"
else
  export DISPLAY=:0.0
  export HOME="$PROFILE_DIR"
  export XDG_CONFIG_HOME="$HOME/config"
  export XDG_DATA_HOME="$HOME/home"
  export SSL_CERT_FILE="${RUNTIME_DIR_LINK}/certs/ca-certificates.crt"
  export SSL_CERT_DIR="$(dirname "$SSL_CERT_FILE")"
  exec "$BIN" $COMMON $EXTRA "$@"
fi
EOF
chmod +x "$LAUNCHER_PATH"

echo
echo "✅ GeForce Infinity installed."
echo "▶️ Launch from: $LAUNCHER_PATH"
echo "   Runtime:     $RUNTIME_DIR_LINK"
echo "🎮 Start+Select = Alt+F4 (gptokeyb, scoped to 'geforceinfinity')"
echo "🖼  Render mode: set RENDER_MODE=mesa|angle|swift|gpuoff (default: mesa)"
