#!/bin/bash

CHROOT_DIR="/storage/my-alpine-chroot"

# Function to check if Alpine chroot is already installed
install_alpine_chroot() {
    echo "🔍 Checking if Alpine chroot is already installed..."
    if [ -d "$CHROOT_DIR" ] && [ -f "$CHROOT_DIR/bin/busybox" ]; then
        echo "✅ Alpine chroot detected. Skipping installation."
    else
        echo "🚀 Installing Alpine chroot..."
        curl -L https://github.com/trashbus99/ROCKNIX-alpine-chroot/raw/main/start-alpine.sh | bash
    fi
}

# Function to update Alpine repositories
update_repositories() {
    echo "🌍 Updating Alpine package sources..."
    chroot "$CHROOT_DIR" /bin/bash -l <<EOF
    apk update
    apk add nano
    echo "🔧 Editing repositories file..."
    sed -i 's|^http.*|# Disabled Default Repo|' /etc/apk/repositories
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/main" > /etc/apk/repositories
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.21/community" >> /etc/apk/repositories
    apk update && apk upgrade
EOF
}

# Ensure Alpine chroot exists before updating repositories
install_alpine_chroot
update_repositories

echo "🎉 Alpine chroot setup complete!"
