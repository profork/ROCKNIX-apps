#!/usr/bin/env bash
set -euo pipefail

CHROOT_DIR="/storage/my-alpine-chroot"
BOOTSTRAP_URL="https://github.com/profork/ROCKNIX-alpinechroot/raw/main/start-alpine.sh"

# 1) Bootstrap if missing
if [[ -d "$CHROOT_DIR" && -x "$CHROOT_DIR/bin/busybox" ]]; then
  echo "✅ Alpine chroot detected—skipping install."
else
  echo "🚀 Installing Alpine chroot from $BOOTSTRAP_URL"
  curl -fsSL "$BOOTSTRAP_URL" | bash
fi

# 2) Update repos inside chroot to v3.22
echo "🌍 Updating Alpine package sources to v3.22…"
chroot "$CHROOT_DIR" /bin/sh -l <<'EOF'
apk update
apk add --no-cache nano
# Remove any existing v3.* entries, then add v3.22 main & community
grep -v '^https://dl-cdn.alpinelinux.org/alpine/v3\.' /etc/apk/repositories > /tmp/repos && mv /tmp/repos /etc/apk/repositories
cat <<REPOS >> /etc/apk/repositories
https://dl-cdn.alpinelinux.org/alpine/v3.22/main
https://dl-cdn.alpinelinux.org/alpine/v3.22/community
REPOS
apk update && apk upgrade --available
EOF

echo "🎉 Alpine chroot setup complete (now on v3.22)!"
