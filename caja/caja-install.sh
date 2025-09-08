#!/bin/bash
# RunImage-based Caja + Engrampa installer for Rocknix (prebuilt image)
# - Two launchers (Caja & Engrampa)
# - Gamepad→mouse mapping (tuned)
# - /storage bound into container at /storage
# - Forces visible X cursor inside the container

clear
echo "Installing Caja+Engrampa RunImage from ROCKNIX-apps repo..."
sleep 3
clear
echo "Thanks to VHSgunzo for RunImage"
sleep 5

### Paths ###
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
RUNIMAGE="$RI_DIR/caja-engrampa-runimage"
LAUNCHER_CAJA="$PORTS_DIR/RunImage-Caja.sh"
LAUNCHER_ENG="$PORTS_DIR/RunImage-Engrampa.sh"
GPTK_FILE="$PORTS_DIR/runimage-caja.gptk"

echo "➤ Creating required directories..."
mkdir -pv "$RI_DIR" "$PORTS_DIR"

### Step 1: Download prebuilt Caja+Engrampa RunImage ###
echo "➤ Downloading prebuilt Caja+Engrampa RunImage..."
curl -L -o "$RUNIMAGE" https://github.com/profork/ROCKNIX-apps/releases/download/r1/caja-engrampa-runimage
chmod +x "$RUNIMAGE"

### Step 2: Write gptokeyb mapping (mouse tuned) ###
echo "➤ Creating gamepad→mouse mapping config..."
cat > "$GPTK_FILE" <<'EOF'
# --- Gamepad → Mouse profile for Caja/Engrampa ---

# Left stick = mouse movement
left_analog_up    = mouse_movement_up
left_analog_down  = mouse_movement_down
left_analog_left  = mouse_movement_left
left_analog_right = mouse_movement_right

# Primary/secondary click
a = mouse_left
b = mouse_right

# Scroll on right stick
right_analog_up    = mouse_wheel_up
right_analog_down  = mouse_wheel_down
right_analog_left  = mouse_wheel_left
right_analog_right = mouse_wheel_right

# Hold L1 to slow cursor for precision
l1 = mouse_slow
mouse_slow_scale = 50    # 50% speed while held

# Page nav on shoulders (optional)
r1 = page_down
l2 = page_up

# Quick exit combo (optional): L1+START+SELECT -> Alt+F4
hotkey = L1+start+select:KEY_LEFTALT+KEY_F4

# --- Mouse tuning ---
mouse_scale = 1024       # higher = slower; 768–1280 is comfy
mouse_delay = 12         # ms between steps (lower = smoother)
deadzone_mode = scaled_radial
deadzone = 1800
deadzone_scale = 8
EOF

### Step 3a: Create Caja launcher ###
echo "➤ Creating Caja launcher..."
cat > "$LAUNCHER_CAJA" <<'EOF'
#!/bin/bash
# Launch Caja via RunImage on Rocknix with pad→mouse and visible cursor

set -euxo pipefail
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
RUNIMAGE="$RI_DIR/caja-engrampa-runimage"
GPTK_FILE="$PORTS_DIR/runimage-caja.gptk"

cd "$RI_DIR"

# Kill gptokeyb on exit
trap 'pkill gptokeyb || true' EXIT

# Start pad→mouse mapping
gptokeyb -p "caja" -c "$GPTK_FILE" -k caja &
sleep 1

# Launch Caja; ensure cursor is visible inside the container
env \
  RIM_ALLOW_ROOT=1 \
  RIM_PORTABLE_HOME=1 \
  RIM_PORTABLE_CONFIG=1 \
  RIM_BIND=/storage:/storage \
  XCURSOR_THEME=Adwaita \
  XCURSOR_SIZE=24 \
  XCURSOR_PATH=/usr/share/icons \
  "$RUNIMAGE" sh -lc 'xsetroot -cursor_name left_ptr || true; exec caja --no-desktop'
EOF
chmod +x "$LAUNCHER_CAJA"

### Step 3b: Create Engrampa launcher ###
echo "➤ Creating Engrampa launcher..."
cat > "$LAUNCHER_ENG" <<'EOF'
#!/bin/bash
# Launch Engrampa via RunImage on Rocknix with pad→mouse and visible cursor

set -euxo pipefail
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
RUNIMAGE="$RI_DIR/caja-engrampa-runimage"
GPTK_FILE="$PORTS_DIR/runimage-caja.gptk"

cd "$RI_DIR"

# Kill gptokeyb on exit
trap 'pkill gptokeyb || true' EXIT

# Start pad→mouse mapping
gptokeyb -p "engrampa" -c "$GPTK_FILE" -k engrampa &
sleep 1

# Launch Engrampa; ensure cursor is visible inside the container
env \
  RIM_ALLOW_ROOT=1 \
  RIM_PORTABLE_HOME=1 \
  RIM_PORTABLE_CONFIG=1 \
  RIM_BIND=/storage:/storage \
  XCURSOR_THEME=Adwaita \
  XCURSOR_SIZE=24 \
  XCURSOR_PATH=/usr/share/icons \
  "$RUNIMAGE" sh -lc 'xsetroot -cursor_name left_ptr || true; exec engrampa'
EOF
chmod +x "$LAUNCHER_ENG"

### Done ###
echo ""
echo "✅ Caja+Engrampa RunImage installed!"
echo " - RunImage:        $RUNIMAGE"
echo " - Gamepad map:     $GPTK_FILE"
echo " - Caja launcher:   $LAUNCHER_CAJA"
echo " - Engrampa launch: $LAUNCHER_ENG"
echo ""
echo "🎮 Launch them from the Ports menu after updating gamelist"
echo "Tip (host once if needed for X11): xhost +si:localuser:root"
