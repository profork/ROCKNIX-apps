#!/bin/bash
# Rocknix Brave Installer (aarch64) — AppImage + Chromium runtime bundle
# - Main Brave.sh uses full GPTK mapping (D-pad, A/B, etc.)
# - GFN/xCloud/Luna launchers use HOTKEY-ONLY GPTK (Alt+F4) so gamepad passes through

set -euo pipefail

# --- Paths & URLs ---
APP_DIR="/storage/Applications/brave"
PORTS_DIR="/storage/roms/ports"
LAUNCH_SCRIPT_DIR="$PORTS_DIR"
PROFILE_DIR="/storage/.brave"
PROFILE_DIR_BASE="/storage/.brave-sites"

GPTK_FULL="$PORTS_DIR/brave.gptk"           # full mapping
GPTK_HOTKEY="$PORTS_DIR/brave_hotkey.gptk" # hotkey-only mapping
BRAVE_LAUNCHER="$PORTS_DIR/Brave.sh"

BRAVE_URL="https://github.com/ivan-hc/Brave-appimage/releases/download/continuous-stable/Brave-Web-Browser-stable-1.81.137-aarch64.AppImage"
RUNTIME_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/chromium-runtime.tar.gz"

BRAVE_APPIMAGE="${APP_DIR}/Brave.AppImage"
RUNTIME_TGZ="${APP_DIR}/chromium-runtime.tar.gz"
RUNTIME_DIR_LINK="${APP_DIR}/chromium-runtime"

echo "🧭 Brave installer for Rocknix (aarch64)…"
sleep 1

# --- Guardrails ---
arch="$(uname -m || true)"
if [ "$arch" != "aarch64" ] && [ "$arch" != "arm64" ]; then
  echo "❌ This installer is for aarch64 only. Detected: $arch"
  exit 1
fi

mkdir -p "$APP_DIR" "$PORTS_DIR" "$PROFILE_DIR" "$PROFILE_DIR_BASE" "$LAUNCH_SCRIPT_DIR"
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

RUNTIME_DIR_FOUND="$(find "$APP_DIR" -type f -name 'libnss3.so' 2>/dev/null | head -n1 || true)"
if [ -z "$RUNTIME_DIR_FOUND" ]; then
  echo "❌ Could not locate runtime 'libnss3.so' after extraction."
  exit 1
fi
RUNTIME_DIR_FOUND="$(dirname "$RUNTIME_DIR_FOUND")/.."
rm -f "$RUNTIME_DIR_LINK"
ln -snf "$RUNTIME_DIR_FOUND" "$RUNTIME_DIR_LINK"
rm -f "$RUNTIME_TGZ"

# --- GPTK mappings ---
echo "🎮 Writing GPTK mappings…"

# Full map (for general browsing / non-gaming)
cat > "$GPTK_FULL" <<'EOF'
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

# HOTKEY-ONLY map (for cloud gaming launchers)
cat > "$GPTK_HOTKEY" <<'EOF'
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# --- Main Brave launcher (full GPTK) ---
echo "🚀 Creating Brave launcher…"
cat > "$BRAVE_LAUNCHER" <<EOF
#!/bin/bash
trap 'pkill -f "gptokeyb -p Brave"' EXIT

export DISPLAY=:0.0
export HOME="$PROFILE_DIR"

export LD_LIBRARY_PATH="$RUNTIME_DIR_LINK/lib:\${LD_LIBRARY_PATH}"
export SSL_CERT_FILE="$RUNTIME_DIR_LINK/certs/ca-certificates.crt"
export SSL_CERT_DIR="\$(dirname "\$SSL_CERT_FILE")"
export APPIMAGE_EXTRACT_AND_RUN=1

EXTRA_FLAGS="--no-sandbox --password-store=basic --enable-gamepad --force-dark-mode"
# If GPU is flaky on some devices, you can add:
EXTRA_FLAGS="\$EXTRA_FLAGS --disable-gpu --use-gl=swiftshader"

# Full mapping ONLY for general Brave use
gptokeyb -p "Brave" -c "$GPTK_FULL" -k brave &>/dev/null &
sleep 1

exec "$BRAVE_APPIMAGE" \$EXTRA_FLAGS "\$@"
EOF
chmod +x "$BRAVE_LAUNCHER"

# --- Helper to create per-site launchers ---
# args: 1) filename  2) URL  3) kiosk|window  4) profile-name  5) gptk_mode=hotkey|none|full
create_brave_launcher() {
  local script_name="$1"
  local url="$2"
  local mode="$3"
  local profname="$4"
  local gptk_mode="$5"
  local launcher_path="$LAUNCH_SCRIPT_DIR/$script_name"
  local flags="--user-data-dir=\"$PROFILE_DIR_BASE/$profname\""

  if [ "$mode" = "kiosk" ]; then
    flags="$flags --kiosk --start-fullscreen --enable-features=OverlayScrollbar"
  fi

  # Decide GPTK line: hotkey-only for gaming, none or full for others
  local gptk_line=""
  case "$gptk_mode" in
    hotkey)
      gptk_line='gptokeyb -p "BraveGaming" -c "'"$GPTK_HOTKEY"'" -k brave &>/dev/null &'
      ;;
    full)
      gptk_line='gptokeyb -p "BraveSite" -c "'"$GPTK_FULL"'" -k brave &>/dev/null &'
      ;;
    none)
      gptk_line=': # no gptokeyb for this launcher'
      ;;
  esac

  cat > "$launcher_path" <<LAUNCH
#!/bin/bash
trap 'pkill -f "gptokeyb -p BraveGaming"; pkill -f "gptokeyb -p BraveSite"' EXIT

$gptk_line
sleep 1

"$BRAVE_LAUNCHER" $flags "$url" "\$@"
LAUNCH
  chmod +x "$launcher_path"
  echo "✅ Created launcher: $launcher_path"
}

echo "🧩 Creating site launchers…"
# Cloud gaming: HOTKEY-ONLY GPTK
create_brave_launcher "Brave-GFN.sh"    "https://play.geforcenow.com/"     "kiosk"  "gfn"     "hotkey"
create_brave_launcher "Brave-Xcloud.sh" "https://www.xbox.com/en-us/play"  "kiosk"  "xcloud"  "hotkey"
create_brave_launcher "Brave-Luna.sh"   "https://luna.amazon.com/"         "kiosk"  "luna"    "hotkey"

# General web (windowed): FULL GPTK (nice for couch navigation)
create_brave_launcher "Brave-Web.sh"    "https://google.com"               "window" "default" "full"

echo
echo "✅ Brave installed."
echo "▶️ Launch from: $BRAVE_LAUNCHER"
echo "   (Runtime: $RUNTIME_DIR_LINK)"
echo "🎮 Start+Select = Alt+F4"
echo "🕹  Gaming launchers (hotkey-only GPTK):"
echo "   - $LAUNCH_SCRIPT_DIR/Brave-GFN.sh"
echo "   - $LAUNCH_SCRIPT_DIR/Brave-Xcloud.sh"
echo "   - $LAUNCH_SCRIPT_DIR/Brave-Luna.sh"
echo "🌐 General:"
echo "   - $LAUNCH_SCRIPT_DIR/Brave-Web.sh"
