#!/bin/bash
# Check that Alpine is installed; install if not present
curl -Ls https://github.com/trashbus99/ROCKNIX.apps/raw/main/base/alpine.sh | bash

CHROOT_DIR="/storage/my-alpine-chroot"
LAUNCH_SCRIPT_DIR="/storage/roms/ports"
LAUNCH_SCRIPT="$LAUNCH_SCRIPT_DIR/chroot-pcmanfm.sh"

mkdir -p "$LAUNCH_SCRIPT_DIR"

# Ensure Alpine chroot exists
if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
    echo "❌ Alpine chroot not found! Run install-alpine-chroot.sh first."
    exit 1
fi

# Install PCManFM, fonts, and dependencies inside the chroot
echo "📦 Installing PCManFM, fonts, and cursor themes..."
chroot "$CHROOT_DIR" /bin/bash -l <<EOF
    apk update
    apk add pcmanfm gvfs gvfs-fuse udev dbus ttf-dejavu fontconfig xcursor-themes
EOF

# Generate launch script
echo "📝 Creating PCManFM launch script..."
cat <<EOF > "$LAUNCH_SCRIPT"
#!/bin/bash

CHROOT_DIR="$CHROOT_DIR"
WAYLAND_SOCKET="/run/user/1000/wayland-0"
X11_SOCKET="/tmp/.X11-unix"
PULSE_DIR="/run/0-runtime-dir/pulse"
PULSE_SOCKET="\$PULSE_DIR/native"
XDG_RUNTIME_DIR="/run/user/1000"

# Ensure runtime directories exist
mkdir -p "\$CHROOT_DIR\$XDG_RUNTIME_DIR"
mkdir -p "\$CHROOT_DIR/tmp"
mkdir -p "\$CHROOT_DIR/mnt/host"
mkdir -p "\$CHROOT_DIR/storage"   # Mount point for host's /storage

# Bind mount essential directories
mount --bind /tmp "\$CHROOT_DIR/tmp"
mount --bind /mnt "\$CHROOT_DIR/mnt/host"
mount --bind /storage "\$CHROOT_DIR/storage"   # Bind mount for host's /storage

# Mount Wayland/X11 sockets
if [ -S "\$WAYLAND_SOCKET" ]; then
    mount --bind "\$WAYLAND_SOCKET" "\$CHROOT_DIR\$WAYLAND_SOCKET"
fi
if [ -d "\$X11_SOCKET" ]; then
    mount --bind "\$X11_SOCKET" "\$CHROOT_DIR\$X11_SOCKET"
fi

# Mount PulseAudio
mkdir -p "\$CHROOT_DIR\$PULSE_DIR"
chmod 777 "\$CHROOT_DIR\$PULSE_DIR"
if [ -S "\$PULSE_SOCKET" ]; then
    mount --bind "\$PULSE_DIR" "\$CHROOT_DIR\$PULSE_DIR"
fi

# Export XDG Environment
export XDG_RUNTIME_DIR="/run/user/1000"
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export PULSE_SERVER=unix:\$PULSE_SOCKET

# Execute PCManFM
exec chroot "\$CHROOT_DIR" env \
    DISPLAY=\$DISPLAY \
    WAYLAND_DISPLAY=\$WAYLAND_DISPLAY \
    PULSE_SERVER=\$PULSE_SERVER \
    XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR \
    /usr/bin/pcmanfm
EOF

chmod +x "$LAUNCH_SCRIPT"
echo "✅ PCManFM installed! Run with:"
echo "   $LAUNCH_SCRIPT"
