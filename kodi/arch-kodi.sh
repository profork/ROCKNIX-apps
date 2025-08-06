#!/bin/bash
# RunImage-based Kodi installer for Rocknix with gamepad mapping and ALSA audio fix

clear
echo "Thanks to VHSGunzo for Runimage..."
sleep 5
clear
# set -euo pipefail

### Paths ###
RI_WORKDIR="/storage/ri"
RI_IMAGE="$RI_WORKDIR/runimage"
RI_BUILT="$RI_WORKDIR/kodi-runimage"
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
LAUNCHER="$PORTS_DIR/RunImage-Kodi.sh"
GPTK_FILE="$PORTS_DIR/runimage-kodi.gptk"

echo "➤ Creating working and ports dirs..."
mkdir -pv "$RI_WORKDIR" "$RI_DIR" "$PORTS_DIR"

### STEP 1: Download latest runimage-aarch64 if missing ###
if [ ! -f "$RI_IMAGE" ]; then
  echo "➤ Downloading runimage-aarch64 from official repo..."
  curl -L -o "$RI_IMAGE" https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-aarch64
  chmod +x "$RI_IMAGE"
else
  echo "➤ RunImage already present."
fi

### STEP 2: Install Kodi into container overlay ###
echo "➤ Installing Kodi into container..."
RIM_ALLOW_ROOT=1 RIM_UNSHARE_MODULES=1 RIM_OVERFS_ID=kodi RIM_KEEP_OVERFS=1 "$RI_IMAGE" \
  rim-shell -c "pacman -Sy --noconfirm && pacman -S --noconfirm kodi"

### STEP 3: Rebuild RunImage ###
echo "➤ Rebuilding RunImage with Kodi..."
RIM_ALLOW_ROOT=1 RIM_OVERFS_ID=kodi "$RI_IMAGE" rim-build "$RI_BUILT"

### STEP 4: Move built image to ports dir ###
mv -f "$RI_BUILT" "$RI_DIR/kodi-runimage"
chmod +x "$RI_DIR/kodi-runimage"

### STEP 5: Write gptokeyb mapping ###
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


### STEP 6: Create launcher ###
cat > "$LAUNCHER" <<EOF
#!/bin/bash
# Launch Kodi via RunImage on Rocknix with gamepad support and internal audio fix

set -euxo pipefail
cd "$RI_DIR"

# Kill on exit
trap 'pkill gptokeyb || :' EXIT

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

echo " - RunImage: $RI_DIR/kodi-runimage"
echo " - Gamepad map: $GPTK_FILE"
echo " - Launcher: $LAUNCHER"
echo " - Rockchip devices may need panfrost enabled"
echo " - Some devices may need Audio device changed in settings"
echo ""
echo ""
echo " - Cleaning Up / Removing Build folder"
rm -rf ~/ri
echo "✅ Kodi RunImage installed!"
