#!/bin/bash
# RunImage-based Chromium installer + launcher generator for Rocknix

set -euo pipefail

# === Directories and constants ===
RI_WORKDIR="/storage/ri"
RI_IMAGE="$RI_WORKDIR/runimage"
RI_BUILT="$RI_WORKDIR/chromium-runimage"
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
GPTK_FILE="$PORTS_DIR/chromium.gptk"

echo "➤ Creating working dirs..."
mkdir -p "$RI_WORKDIR" "$RI_DIR" "$PORTS_DIR"

# === Step 1: Fetch RunImage ===
if [ ! -f "$RI_IMAGE" ]; then
  echo "➤ Downloading runimage-aarch64..."
  curl -L -o "$RI_IMAGE" https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-aarch64
  chmod +x "$RI_IMAGE"
else
  echo "✔ RunImage already exists."
fi

# === Step 2: Install Chromium in overlay ===
echo "➤ Installing Chromium in container overlay..."
RIM_ALLOW_ROOT=1 RIM_OVERFS_ID=chromium RIM_KEEP_OVERFS=1 "$RI_IMAGE" \
  rim-shell -c "pacman -Sy --noconfirm && pacman -S --noconfirm chromium"

# === Step 3: Rebuild image ===
echo "➤ Rebuilding Chromium RunImage..."
RIM_ALLOW_ROOT=1 RIM_OVERFS_ID=chromium "$RI_IMAGE" rim-build "$RI_BUILT"

# === Step 4: Move final image ===
mv -f "$RI_BUILT" "$RI_DIR/chromium-runimage"
chmod +x "$RI_DIR/chromium-runimage"

# === Step 5: GPTK map (start+select = Alt+F4) ===
cat > "$GPTK_FILE" <<EOF
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# === Step 6: Launcher generator ===
create_launcher() {
  local script="$PORTS_DIR/$1"
  local url="$2"
  local mode="$3"
  local args="--no-sandbox --enable-gamepad"

  [ "$mode" = "kiosk" ] && args+=" --kiosk --start-fullscreen"

  cat > "$script" <<EOF
#!/bin/bash
# Chromium RunImage launcher: $1

set -euxo pipefail
cd "$RI_DIR"

trap 'pkill gptokeyb || :' EXIT

gptokeyb -p "chromium" -c "$GPTK_FILE" -k chromium &
sleep 1

# Launch Chromium with Pulse/Wayland bindings if available
env \\
  RIM_ALLOW_ROOT=1 \\
  RIM_PORTABLE_HOME=1 \\
  RIM_PORTABLE_CONFIG=1 \\
  RIM_BIND=/run/user/0/pulse/native:/run/user/0/pulse/native,/storage:/media/storage \\
  ./chromium-runimage chromium $args "$url"
EOF

  chmod +x "$script"
  echo "✅ Created launcher: $script"
}

# === Step 7: Generate launchers ===
create_launcher "runimage-chromium-geforcenow.sh" "https://play.geforcenow.com/" "kiosk"
create_launcher "runimage-chromium-amazonluna.sh" "https://luna.amazon.com/" "kiosk"
create_launcher "runimage-chromium-xcloud.sh" "https://www.xbox.com/en-us/play" "kiosk"
create_launcher "runimage-chromium.sh" "https://google.com" "window"

echo "✅ All RunImage Chromium launchers created!"
echo "✅ RunImage: $RI_DIR/chromium-runimage"
echo "🕹  Gamepad hotkey: $GPTK_FILE"
echo "ℹ️  Select+Start closes Chromium"
