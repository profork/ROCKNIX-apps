#!/bin/bash
# RunImage-based Kodi installer for Rocknix with gamepad mapping and ALSA audio fix

clear
echo "Installing Kodi RunImage from ROCKNIX-apps repo..."
sleep 3
clear
echo "Thanks to VHSgunzo for Runimage"
sleep 5

### Paths ###
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
KODI_IMAGE="$RI_DIR/kodi-runimage"
LAUNCHER="$PORTS_DIR/RunImage-Kodi.sh"
GPTK_FILE="$PORTS_DIR/runimage-kodi.gptk"

echo "➤ Creating required directories..."
mkdir -pv "$RI_DIR" "$PORTS_DIR"

### Step 1: Download prebuilt Kodi RunImage ###
echo "➤ Downloading prebuilt Kodi RunImage..."
curl -L -o "$KODI_IMAGE" https://github.com/profork/ROCKNIX-apps/releases/download/r1/kodi-runimage
chmod +x "$KODI_IMAGE"

### Step 2: Write gptokeyb mapping ###
echo "➤ Creating gamepad mapping config..."
cat > "$GPTK_FILE" <<EOF
# D-pad → arrow keys
up = up
down = down
left = left
right = right

# Face buttons
a = enter
b = esc
x = space
y = space

# Start/Select
start = enter
select = esc

# Left analog → D-pad
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right

# Hotkey (L1+start+select) → Alt+F4
hotkey = L1+start+select:KEY_LEFTALT+KEY_F4
EOF

### Step 3: Create launcher ###
echo "➤ Creating launcher script..."
cat > "$LAUNCHER" <<EOF
#!/bin/bash
# Launch Kodi via RunImage on Rocknix with gamepad support and ALSA audio fix

set -euxo pipefail
cd "$RI_DIR"

# Kill gptokeyb on exit
trap 'pkill gptokeyb || true' EXIT

# Start gamepad mapping
gptokeyb -p "kodi" -c "$GPTK_FILE" -k kodi &
sleep 1

# Launch Kodi with ALSA backend
env \\
  RIM_ALLOW_ROOT=1 \\
  RIM_PORTABLE_HOME=1 \\
  RIM_PORTABLE_CONFIG=1 \\
  RIM_BIND=/storage:/media/storage \\
  ./kodi-runimage kodi --audio-backend=alsa
EOF

chmod +x "$LAUNCHER"

### Done ###
echo ""
echo "✅ Kodi RunImage installed!"
echo " - RunImage: $KODI_IMAGE"
echo " - Gamepad map: $GPTK_FILE"
echo " - Launcher: $LAUNCHER"
echo ""
echo "🎮 Launch it from Ports menu after updating gamelist"
echo "Rockchip Devices might need panfrost enabled"
echo "Some devices might need audio output device toggled in Kodi Audio settings"
echo "SM8250 devices may need modification to    --audio-backend=alsa+pulseudio   flag in Runimage-Kodi Launcher in ports for audio to work"
