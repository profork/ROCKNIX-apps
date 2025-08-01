#!/bin/bash
echo "ROCKNIX.apps does not endorse piracy.  Use repsonsilbly."
sleep 5

#check that alpine is installed; install if not present
curl -Ls https://github.com/profork/ROCKNIX.apps/raw/main/base/alpine.sh | bash

#!/bin/bash

CHROOT_DIR="/storage/my-alpine-chroot"
LAUNCH_SCRIPT_DIR="/storage/roms/ports"
LAUNCH_SCRIPT="$LAUNCH_SCRIPT_DIR/chroot-qbittorrent.sh"

mkdir -p "$LAUNCH_SCRIPT_DIR"

# Ensure Alpine chroot exists
if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
    echo "❌ Alpine chroot not found! Run install-alpine-chroot.sh first."
    exit 1
fi

# Install qBittorrent inside the chroot
echo "📦 Installing qBittorrent..."
chroot "$CHROOT_DIR" /bin/bash -l <<EOF
    apk update
    apk add qbittorrent
EOF

# Generate launch script
echo "📝 Creating qBittorrent launch script..."
cat <<EOF > "$LAUNCH_SCRIPT"
#!/bin/bash

CHROOT_DIR="$CHROOT_DIR"
WAYLAND_SOCKET="/run/user/1000/wayland-0"
PULSE_DIR="/run/0-runtime-dir/pulse"
PULSE_SOCKET="\$PULSE_DIR/native"

mkdir -p "\$CHROOT_DIR/run/user/1000"
mkdir -p "\$CHROOT_DIR\$PULSE_DIR"
chmod 777 "\$CHROOT_DIR\$PULSE_DIR"

if ! mountpoint -q "\$CHROOT_DIR\$WAYLAND_SOCKET"; then
    mount --bind "\$WAYLAND_SOCKET" "\$CHROOT_DIR\$WAYLAND_SOCKET"
fi
if ! mountpoint -q "\$CHROOT_DIR\$PULSE_DIR"; then
    mount --make-private "\$PULSE_DIR"
    mount --bind "\$PULSE_DIR" "\$CHROOT_DIR\$PULSE_DIR"
fi

exec chroot "\$CHROOT_DIR" env \
    WAYLAND_DISPLAY=wayland-0 \
    PULSE_SERVER=unix:\$PULSE_SOCKET \
    /usr/bin/qbittorrent
EOF

chmod +x "$LAUNCH_SCRIPT"
echo "✅ qBittorrent installed! Run with:"
echo "   $LAUNCH_SCRIPT"
