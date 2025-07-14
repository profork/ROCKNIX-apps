#!/bin/bash
# install_kodi_chroot_debug.sh
set -euxo pipefail

### Paths ###
CHROOT_DIR="/storage/my-alpine-chroot"
PORTS_DIR="/storage/roms/ports"
GPTK_FILE="$PORTS_DIR/chroot-kodi.gptk"
LAUNCHER="$PORTS_DIR/chroot-kodi.sh"

echo "DEBUG: CHROOT_DIR = $CHROOT_DIR"
echo "DEBUG: PORTS_DIR  = $PORTS_DIR"

# 1) Ensure ports dir exists
echo "➤ Creating ports dir..."
mkdir -pv "$PORTS_DIR"

# 2) Ensure Alpine chroot
if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
  echo "➤ Alpine chroot missing. Installing..."
  curl -Ls https://github.com/profork/ROCKNIX-apps/raw/main/base/alpine.sh | bash
else
  echo "➤ Alpine chroot already present."
fi

# 3) Install Kodi & ALSA
echo "➤ Installing Kodi & ALSA in chroot..."
chroot "$CHROOT_DIR" /bin/sh -l <<EOF
apk update
apk add --no-cache kodi alsa-utils alsa-lib
EOF

# 4) Write GPTK mapping
echo "➤ Writing GPTK file to: $GPTK_FILE"
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
echo "➤ GPTK file content:"
cat "$GPTK_FILE"

# 5) Generate launcher
echo "➤ Writing launcher script to: $LAUNCHER"
cat > "$LAUNCHER" <<'EOF'
#!/bin/bash
set -euxo pipefail

CHROOT_DIR="/storage/my-alpine-chroot"
GPTK_FILE="/storage/roms/ports/chroot-kodi.gptk"

# Clean up
trap 'pkill gptokeyb || :; exit' EXIT

# Mount points
mkdir -pv "$CHROOT_DIR/tmp/.X11-unix" "$CHROOT_DIR/dev/snd" "$CHROOT_DIR/storage"

# Bind mounts
mountpoint -q "$CHROOT_DIR/tmp/.X11-unix" || mount --bind /tmp/.X11-unix "$CHROOT_DIR/tmp/.X11-unix"
mountpoint -q "$CHROOT_DIR/dev/snd"      || mount --bind /dev/snd "$CHROOT_DIR/dev/snd"
mountpoint -q "$CHROOT_DIR/storage"      || mount --bind /storage "$CHROOT_DIR/storage"

# Start mapping
echo "Starting gptokeyb…"
gptokeyb -p "kodi" -c "$GPTK_FILE" -k kodi &
sleep 1

# Launch Kodi
exec chroot "$CHROOT_DIR" env DISPLAY=:0 kodi
EOF

chmod +x "$LAUNCHER"
echo "✅  Install complete!"
echo "   - GPTK mapping: $GPTK_FILE"
echo "   - Launcher script: $LAUNCHER"
echo "   -Rockchip users may need panfrost drivers enabled"
