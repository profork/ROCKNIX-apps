#!/bin/bash
# RunImage-based Caja + Engrampa installer for Rocknix
# - Two launchers (Caja & Engrampa)
# - Gamepad→mouse with tuned settings
# - RIM_BIND=/storage:/storage so Caja sees host content

clear
echo "Thanks to VHSGunzo for RunImage..."
sleep 2
clear
# set -euo pipefail   # (left relaxed for noisy envs)

### Paths ###
RI_WORKDIR="/storage/ri"
RI_IMAGE="$RI_WORKDIR/runimage"
RI_BUILT="$RI_WORKDIR/caja-engrampa-runimage"
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
LAUNCHER_CAJA="$PORTS_DIR/RunImage-Caja.sh"
LAUNCHER_ENG="$PORTS_DIR/RunImage-Engrampa.sh"
GPTK_FILE="$PORTS_DIR/runimage-caja.gptk"

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

### STEP 2: Install Caja + Engrampa into container overlay ###
echo "➤ Installing Caja + Engrampa into container..."
RIM_ALLOW_ROOT=1 RIM_UNSHARE_MODULES=1 RIM_OVERFS_ID=caja-engrampa RIM_KEEP_OVERFS=1 "$RI_IMAGE" \
  rim-shell -c '
    set -eux
    pacman -Sy --noconfirm
    pacman -S --noconfirm \
      caja engrampa \
      libarchive p7zip unzip zip unrar zstd xz bzip2 gzip lrzip lzop \
      gvfs shared-mime-info \
      gtk3 gsettings-desktop-schemas gdk-pixbuf2 librsvg \
      adwaita-icon-theme hicolor-icon-theme \
      fontconfig ttf-dejavu noto-fonts xorg-xhost

    # Refresh caches to avoid blank UI/icons issues
    fc-cache -fsv || true
    gdk-pixbuf-query-loaders --update-cache || true
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true

    which caja
    which engrampa
    engrampa --version || true
    mkdir -p /storage
  '

### STEP 3: Rebuild RunImage ###
echo "➤ Rebuilding RunImage with Caja + Engrampa..."
RIM_ALLOW_ROOT=1 RIM_OVERFS_ID=caja-engrampa "$RI_IMAGE" rim-build "$RI_BUILT"

### STEP 4: Move built image to ports dir ###
mv -f "$RI_BUILT" "$RI_DIR/caja-engrampa-runimage"
chmod +x "$RI_DIR/caja-engrampa-runimage"

### STEP 5: Write gptokeyb mapping with tuned mouse ###
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
# Lower mouse_scale = faster cursor; higher = slower. 768–1280 is a comfy range.
mouse_scale = 1024
# Delay (ms) between mouse movement steps; lower = smoother/faster, higher = coarser.
mouse_delay = 12
# Deadzone behavior; "scaled_radial" = consistent threshold in all directions.
deadzone_mode = scaled_radial
deadzone = 1800          # stick noise cutoff (adjust if drift)
deadzone_scale = 8       # curve/accel shaping beyond deadzone
EOF

### STEP 6a: Create Caja launcher (bind /storage → /storage) ###
cat > "$LAUNCHER_CAJA" <<EOF
#!/bin/bash
# Launch Caja via RunImage with pad→mouse support and /storage bind

set -euxo pipefail
cd "$RI_DIR"

trap 'pkill gptokeyb || :' EXIT

# Start pad→mouse mapping
gptokeyb -p "caja" -c "$GPTK_FILE" -k caja &
sleep 1

# Launch Caja inside the rebased RunImage
env \\
  RIM_ALLOW_ROOT=1 \\
  RIM_PORTABLE_HOME=1 \\
  RIM_PORTABLE_CONFIG=1 \\
  RIM_BIND=/storage:/storage \\
  ./caja-engrampa-runimage caja --no-desktop
EOF
chmod +x "$LAUNCHER_CAJA"

### STEP 6b: Create Engrampa launcher (bind /storage → /storage) ###
cat > "$LAUNCHER_ENG" <<EOF
#!/bin/bash
# Launch Engrampa via RunImage with pad→mouse support and /storage bind

set -euxo pipefail
cd "$RI_DIR"

trap 'pkill gptokeyb || :' EXIT

# Start pad→mouse mapping
gptokeyb -p "engrampa" -c "$GPTK_FILE" -k engrampa &
sleep 1

# Launch Engrampa inside the rebased RunImage
env \\
  RIM_ALLOW_ROOT=1 \\
  RIM_PORTABLE_HOME=1 \\
  RIM_PORTABLE_CONFIG=1 \\
  RIM_BIND=/storage:/storage \\
  ./caja-engrampa-runimage engrampa
EOF
chmod +x "$LAUNCHER_ENG"

### Done ###
echo " - RunImage:        $RI_DIR/caja-engrampa-runimage"
echo " - Gamepad map:     $GPTK_FILE"
echo " - Caja launcher:   $LAUNCHER_CAJA"
echo " - Engrampa launch: $LAUNCHER_ENG"
echo ""
echo "Tip (host once if needed): xhost +si:localuser:root"
echo ""
echo " - Cleaning Up / Removing Build folder"
rm -rf ~/ri || true
echo "✅ Caja+Engrampa RunImage installed (two launchers, mouse tuned, /storage bound)!"
