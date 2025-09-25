#!/bin/bash
# Rocknix Ungoogled Chromium Installer (aarch64) — AppImage + Chromium runtime bundle
# - Installs to /storage/Applications/ungoogled-chromium
# - Pre-extracts the AppImage once (so we can bypass its wrapper)
# - Creates /storage/roms/ports/UngoogledChromium.sh (NO gptokeyb)
# - Launcher runs inner chrome via runtime's run-with-runtime.sh for NSS/NSPR

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/ungoogled-chromium"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.ungoogled-chromium"

APP_URL="https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/releases/download/140.0.7339.185-1/ungoogled-chromium-140.0.7339.185-1-arm64.AppImage"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/chromium-runtime.tar.gz"

APPIMAGE_PATH="${APP_DIR}/UngoogledChromium.AppImage"
EXTRACT_DIR="${APP_DIR}/ugc-extracted"
RUNTIME_TGZ="${APP_DIR}/chromium-runtime.tar.gz"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"

LAUNCHER_PATH="${PORTS_DIR}/UngoogledChromium.sh"

echo "🧭 Ungoogled Chromium installer for Rocknix (aarch64)…"
sleep 1

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ This installer is for aarch64/arm64 only. Detected: $arch"
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

# --- Fetch Chromium runtime bundle (NSPR/NSS + certs) ---
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
ln -snf "$RUNTIME_DIR_FOUND" "$RUNTIME_DIR_LINK"
rm -f "$RUNTIME_TGZ"

# Extra sanity: make sure NSPR and NSS are present
if [ ! -f "${RUNTIME_DIR_LINK}/lib/libnspr4.so" ] || [ ! -f "${RUNTIME_DIR_LINK}/lib/libnss3.so" ]; then
  echo "❌ Runtime missing libnspr4.so or libnss3.so in ${RUNTIME_DIR_LINK}/lib"
  exit 1
fi

# --- Pre-extract the AppImage (so we can bypass the AppImage wrapper) ---
echo "🗜️  Extracting AppImage payload…"
rm -rf "$EXTRACT_DIR"
TMPDIR="${APP_DIR}/_extract-tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
( cd "$TMPDIR" && "$APPIMAGE_PATH" --appimage-extract >/dev/null )
mv "$TMPDIR/squashfs-root" "$EXTRACT_DIR"
rm -rf "$TMPDIR"

# Make sure inner chrome is present & executable
CHROME_BIN=""
for CAND in \
  "${EXTRACT_DIR}/opt/ungoogled-chromium/chrome" \
  "${EXTRACT_DIR}/opt/chromium/chrome" \
  "${EXTRACT_DIR}/chrome" \
  "${EXTRACT_DIR}/usr/bin/chromium"
do
  if [ -x "$CAND" ]; then CHROME_BIN="$CAND"; break; fi
done
if [ -z "$CHROME_BIN" ]; then
  echo "❌ Couldn’t locate inner chrome binary under $EXTRACT_DIR"
  exit 1
fi
chmod +x "$CHROME_BIN" || true

# --- Write single Ports launcher (no gptokeyb) ---
echo "🚀 Creating UngoogledChromium launcher…"
cat > "$LAUNCHER_PATH" <<'EOF'
#!/bin/bash
# Ungoogled Chromium — Rocknix launcher (no gptokeyb)
# - Runs inner chrome via Chromium runtime's run-with-runtime.sh
# - Forces X11 surface for compatibility

set -euo pipefail

APP_DIR="/storage/Applications/ungoogled-chromium"
EXTRACT_DIR="${APP_DIR}/ugc-extracted"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"
PROFILE_DIR="/storage/.ungoogled-chromium"

# Re-discover inner chrome (in case of future updates)
CHROME_BIN=""
for CAND in \
  "${EXTRACT_DIR}/opt/ungoogled-chromium/chrome" \
  "${EXTRACT_DIR}/opt/chromium/chrome" \
  "${EXTRACT_DIR}/chrome" \
  "${EXTRACT_DIR}/usr/bin/chromium"
do
  if [ -x "$CAND" ]; then CHROME_BIN="$CAND"; break; fi
done
if [ -z "$CHROME_BIN" ]; then
  echo "❌ Inner chrome binary not found under $EXTRACT_DIR"
  echo "   Try re-running the installer to re-extract the AppImage."
  exit 1
fi

# Touch/KB/mouse only — no gptokeyb
trap ':' EXIT

mkdir -p "${PROFILE_DIR}/config" "${PROFILE_DIR}/home"

# Common env
export DISPLAY=:0.0
export HOME="$PROFILE_DIR"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/home"

# Wire certs (runtime wrapper will handle LD_LIBRARY_PATH)
export SSL_CERT_FILE="${RUNTIME_DIR_LINK}/certs/ca-certificates.crt"
export SSL_CERT_DIR="$(dirname "$SSL_CERT_FILE")"

# Flags: force X11; add SwiftShader if GPU is flaky
EXTRA_FLAGS="--no-sandbox --password-store=basic --enable-gamepad --force-dark-mode --ozone-platform-hint=x11"
# Uncomment if needed:
# EXTRA_FLAGS="$EXTRA_FLAGS --disable-gpu --use-gl=swiftshader"

# Prefer runtime wrapper to ensure NSS/NSPR libs are prepended
RWR="$(find "$RUNTIME_DIR_LINK" -type f -name 'run-with-runtime.sh' -maxdepth 2 2>/dev/null | head -n1 || true)"
if [ -x "$RWR" ]; then
  exec "$RWR" "$CHROME_BIN" $EXTRA_FLAGS "$@"
else
  # Fallback: manual LD path (less robust if app alters env)
  export LD_LIBRARY_PATH="${RUNTIME_DIR_LINK}/lib:${LD_LIBRARY_PATH-}"
  exec "$CHROME_BIN" $EXTRA_FLAGS "$@"
fi
EOF
chmod +x "$LAUNCHER_PATH"

echo
echo "✅ Ungoogled Chromium installed."
echo "▶️ Launch from: $LAUNCHER_PATH"
echo "   AppImage:    $APPIMAGE_PATH"
echo "   Extracted:   $EXTRACT_DIR"
echo "   Runtime:     $RUNTIME_DIR_LINK"
echo "ℹ️  No gamepad mapping is started (touch/keyboard/mouse only)."
