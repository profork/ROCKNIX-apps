#!/bin/bash
# Rocknix Chiaki-NG Installer (aarch64) — AppImage + chaiki-runtime bundle (no symlinks)

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/chiaki-ng"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.chiaki-ng"

APP_URL="https://github.com/streetpea/chiaki-ng/releases/download/v1.9.9/chiaki-ng.AppImage_arm64"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/raw/main/chiaki/chiaki-runtime.tar.gz"

APPIMAGE_PATH="${APP_DIR}/ChiakiNG.AppImage"
EXTRACT_DIR="${APP_DIR}/chiaki-extracted"

RUNTIME_TGZ="${APP_DIR}/chiaki-runtime.tar.gz"
RUNTIME_DIR="${APP_DIR}/chromium-runtime"   # real directory after extraction

LAUNCHER_PATH="${PORTS_DIR}/ChiakiNG.sh"

echo "🧭 Chiaki-NG installer for Rocknix (aarch64)…"
sleep 1

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ This installer is for aarch64/arm64 only. Detected: $arch"
  exit 1
fi

mkdir -p "$APP_DIR" "$PORTS_DIR" "$PROFILE_DIR"
cd "$APP_DIR"

# --- Fetch Chiaki-NG AppImage ---
echo "🔽 Downloading Chiaki-NG AppImage…"
rm -f "$APPIMAGE_PATH"
if ! wget -O "$APPIMAGE_PATH" "$APP_URL"; then
  echo "wget failed, trying curl"
  curl -L -o "$APPIMAGE_PATH" "$APP_URL"
fi
chmod +x "$APPIMAGE_PATH"

# --- Fetch chaiki runtime bundle (your chromium-runtime with extra libs) ---
echo "🔽 Downloading chaiki runtime…"
rm -f "$RUNTIME_TGZ"
if ! wget -O "$RUNTIME_TGZ" "$RUNTIME_URL"; then
  echo "wget failed, trying curl"
  curl -L -o "$RUNTIME_TGZ" "$RUNTIME_URL"
fi

echo "📦 Extracting runtime…"
# Remove any old runtime (dir or symlink) so we don't collide/mix
rm -rf "$RUNTIME_DIR"

# Extract into APP_DIR; tarball must contain top-level chromium-runtime/
tar -xzf "$RUNTIME_TGZ" -C "$APP_DIR"
rm -f "$RUNTIME_TGZ"

# Validate runtime layout (no symlink tricks, just the real dir)
if [ ! -f "${RUNTIME_DIR}/lib/libnss3.so" ]; then
  echo "❌ Runtime seems incomplete: ${RUNTIME_DIR}/lib/libnss3.so not found."
  echo "   Ensure the tarball’s top-level folder is exactly 'chromium-runtime/'."
  exit 1
fi
chmod +x "${RUNTIME_DIR}/run-with-runtime.sh" 2>/dev/null || true

# --- Pre-extract the AppImage ---
echo "🗜️  Extracting AppImage payload…"
rm -rf "$EXTRACT_DIR"
TMPDIR="${APP_DIR}/_extract-tmp"
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
( cd "$TMPDIR" && "$APPIMAGE_PATH" --appimage-extract >/dev/null )
mv "$TMPDIR/squashfs-root" "$EXTRACT_DIR"
rm -rf "$TMPDIR"

# Find inner executable
CHIAKI_BIN=""
for C in \
  "${EXTRACT_DIR}/AppRun" \
  "${EXTRACT_DIR}/usr/bin/chiaki-ng" \
  "${EXTRACT_DIR}/usr/bin/chiaki" \
  "${EXTRACT_DIR}/chiaki-ng" \
  "${EXTRACT_DIR}/chiaki"
do
  [ -x "$C" ] && CHIAKI_BIN="$C" && break
done
[ -n "$CHIAKI_BIN" ] || { echo "❌ Couldn’t locate inner Chiaki-NG binary under $EXTRACT_DIR"; exit 1; }
chmod +x "$CHIAKI_BIN" || true

# (Nice-to-have) Prefer ALSA-capable system SDL2 persistently if present
if [ -f /usr/lib/libSDL2-2.0.so.0 ]; then
  echo "🎧 Adding system SDL2 (ALSA-capable) to runtime…"
  cp -n /usr/lib/libSDL2-2.0.so.0 "${RUNTIME_DIR}/lib/" || true
  ln -snf libSDL2-2.0.so.0 "${RUNTIME_DIR}/lib/libSDL2.so"
fi

# --- Create single Ports launcher (no gptokeyb), robust cwd & logging ---
echo "🚀 Creating ChiakiNG launcher…"
cat > "$LAUNCHER_PATH" <<'EOF'
#!/bin/bash
# Chiaki-NG — Rocknix launcher (no gptokeyb), single-shot & robust cwd/logging

set -Eeuo pipefail

APP_DIR="/storage/Applications/chiaki-ng"
EXTRACT_DIR="${APP_DIR}/chiaki-extracted"
RUNTIME_DIR="${APP_DIR}/chromium-runtime"
RUNTIME_LIB="${RUNTIME_DIR}/lib"
PROFILE_DIR="/storage/.chiaki-ng"
LOG="/tmp/chiaki-ng.log"

ts(){ date '+%Y-%m-%d %H:%M:%S'; }
log(){ echo "[$(ts)] $*" | tee -a "$LOG"; }
: > "$LOG"

# Find inner Chiaki binary
CHIAKI_BIN=""
for C in \
  "${EXTRACT_DIR}/AppRun" \
  "${EXTRACT_DIR}/usr/bin/chiaki-ng" \
  "${EXTRACT_DIR}/usr/bin/chiaki" \
  "${EXTRACT_DIR}/chiaki-ng" \
  "${EXTRACT_DIR}/chiaki"
do
  [ -x "$C" ] && CHIAKI_BIN="$C" && break
done
[ -n "$CHIAKI_BIN" ] || { log "❌ Inner Chiaki-NG binary not found under $EXTRACT_DIR"; exit 1; }
chmod +x "$CHIAKI_BIN" || true

# Profile / display
export DISPLAY=:0.0
export HOME="$PROFILE_DIR"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/home"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

# Locale (quietly prefer UTF-8 if present)
if command -v locale >/dev/null 2>&1; then
  UTF8=$(locale -a 2>/dev/null | grep -i -E '^(C\.UTF-8|C\.utf8|en_US\.UTF-8|en_US\.utf8)$' | head -n1 || true)
  [ -n "$UTF8" ] && { export LANG="$UTF8" LC_ALL="$UTF8"; }
fi

# Qt plugins
PLATFORM_DIR=""
for P in \
  "${EXTRACT_DIR}/usr/lib/qt6/plugins/platforms" \
  "${EXTRACT_DIR}/usr/lib/qt/plugins/platforms" \
  "${EXTRACT_DIR}/usr/plugins/platforms" \
  "${EXTRACT_DIR}/plugins/platforms" \
  "${EXTRACT_DIR}/lib/qt6/plugins/platforms" \
  "${EXTRACT_DIR}/lib/qt/plugins/platforms"
do
  [ -d "$P" ] && PLATFORM_DIR="$P" && break
done
[ -n "$PLATFORM_DIR" ] || { log "❌ Qt platforms/ dir not found in AppImage"; exit 1; }

export QT_QPA_PLATFORM_PLUGIN_PATH="$PLATFORM_DIR"
QT_PLUGIN_ROOT="$(dirname "$PLATFORM_DIR")"
export QT_PLUGIN_PATH="$QT_PLUGIN_ROOT${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"

# Prefer Wayland if socket exists & plugin bundled; else XCB
UID_DIR="/run/user/$(id -u)"
WAYLAND_SOCK="${XDG_RUNTIME_DIR:-$UID_DIR}/wayland-0"
if [ -S "$WAYLAND_SOCK" ] && ls "$PLATFORM_DIR"/libqwayland*.so >/dev/null 2>&1; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-$UID_DIR}"
  export WAYLAND_DISPLAY="wayland-0"
  export QT_QPA_PLATFORM="wayland"
else
  [ -f "$PLATFORM_DIR/libqxcb.so" ] || { log "❌ xcb plugin not found in $PLATFORM_DIR"; exit 1; }
  export QT_QPA_PLATFORM="xcb"
fi
export QT_ENABLE_HIGHDPI_SCALING=1
export QT_SCALE_FACTOR="${QT_SCALE_FACTOR:-1}"

# Library paths: AppImage + runtime + system
APP_LIBS=""
for D in \
  "${EXTRACT_DIR}/usr/lib" \
  "${EXTRACT_DIR}/usr/lib/aarch64-linux-gnu" \
  "${EXTRACT_DIR}/lib" \
  "${EXTRACT_DIR}/lib64"
do
  [ -d "$D" ] && APP_LIBS="${APP_LIBS:+$APP_LIBS:}$D"
done
SYS_LIBS="/usr/lib/aarch64-linux-gnu:/usr/lib:/lib/aarch64-linux-gnu:/lib"
LD_MERGED=""
[ -n "$APP_LIBS" ]    && LD_MERGED="$APP_LIBS"
[ -d "$RUNTIME_LIB" ] && LD_MERGED="${LD_MERGED:+$LD_MERGED:}$RUNTIME_LIB"
LD_MERGED="${LD_MERGED:+$LD_MERGED:}$SYS_LIBS"
export LD_LIBRARY_PATH="$LD_MERGED${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Certs
export SSL_CERT_FILE="${RUNTIME_DIR}/certs/ca-certificates.crt"
export SSL_CERT_DIR="$(dirname "$SSL_CERT_FILE")"

# Prefer system SDL2 (ALSA-capable) and ALSA backend
[ -f /usr/lib/libSDL2-2.0.so.0 ] && export LD_PRELOAD="/usr/lib/libSDL2-2.0.so.0${LD_PRELOAD:+:$LD_PRELOAD}"
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-alsa}"

# cd into the extracted payload (some AppImages expect this)
cd "$EXTRACT_DIR"

# Runtime wrapper (preferred), keep output visible and logged
# RWR="$(find "$RUNTIME_DIR" -maxdepth 4 -type f -name 'run-with-runtime.sh' 2>/dev/null | head -n1 || true)"
#if [ -x "$RWR" ]; then
#  "$RWR" "$CHIAKI_BIN" "$@" 2>&1 | tee -a "$LOG"
#  exit ${PIPESTATUS[0]}
#else
  "$CHIAKI_BIN" "$@" 2>&1 | tee -a "$LOG"
#  exit ${PIPESTATUS[0]}
# fi
EOF
chmod +x "$LAUNCHER_PATH"

echo
echo "✅ Chiaki-NG installed."
echo "▶️ Launch from: $LAUNCHER_PATH"
echo "   AppImage:    $APPIMAGE_PATH"
echo "   Extracted:   $EXTRACT_DIR"
echo "   Runtime:     $RUNTIME_DIR (real dir, no symlink)"
echo "ℹ️  No gptokeyb. Default audio is ALSA (override via SDL_AUDIODRIVER if needed)."
