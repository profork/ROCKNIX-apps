#!/bin/sh
# install-flatpak-wrapper.sh — Rocknix: install 'flatpak' wrapper that runs inside your RunImage
# - Namespaced assets under /storage/ri/flatpak
# - Wrapper only uses dbus-run-session for `flatpak run …`
# - Adds XDG_DATA_DIRS so desktop entries show up without a session restart

clear
echo "Installing Flatpak RunImage from ROCKNIX-apps repo..."
sleep 3
clear
echo "Thanks to VHSgunzo for Runimage"
sleep 5

set -eu

# ===== CONFIG: your hosted RunImage =====
RUNIMAGE_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/runimage-flatpak-aarch64"
RUNIMAGE_SHA256=""  # optional checksum; set to enable verification

# ===== Paths (namespaced, no conflicts) =====
ROOT="/storage"
NS="flatpak"
RI_BASE="$ROOT/ri/$NS"
RI_IMAGE="$RI_BASE/runimage"     # downloaded image
TMPDIR_HOST="$RI_BASE/tmp"       # extract dir (suid-capable)
OVERLAYS="$RI_BASE/overlays"     # overlays home
OVERFS_ID="flatpak"              # overlay name (scoped by OVERLAYS dir)
FLATPAK_DB="$ROOT/flatpak"       # persistent /var/lib/flatpak
BIN_DIR="$ROOT/bin"
WRAP="$BIN_DIR/flatpak"          # host-visible command: 'flatpak'

# ===== Ensure dirs =====
mkdir -p "$RI_BASE" "$TMPDIR_HOST" "$OVERLAYS" "$FLATPAK_DB" "$BIN_DIR"

echo "[*] Downloading prebuilt RunImage to $RI_IMAGE …"
curl -L --fail -o "$RI_IMAGE" "$RUNIMAGE_URL"
chmod +x "$RI_IMAGE"

if [ -n "$RUNIMAGE_SHA256" ]; then
  echo "$RUNIMAGE_SHA256  $RI_IMAGE" | sha256sum -c -
fi

# ===== Write/Update the host-side wrapper =====
cat > "$WRAP" <<'EOF'
#!/bin/sh
# /storage/bin/flatpak — proxy all 'flatpak …' commands into the namespaced RunImage

set -eu

ROOT="/storage"
NS="flatpak"
RI_BASE="$ROOT/ri/$NS"
RI_IMAGE="$RI_BASE/runimage"
TMPDIR_HOST="$RI_BASE/tmp"
OVERLAYS="$RI_BASE/overlays"
OVERFS_ID="flatpak"
FLATPAK_DB="$ROOT/flatpak"

# Ensure dirs (idempotent)
mkdir -p "$TMPDIR_HOST" "$OVERLAYS" "$FLATPAK_DB" || true

# GUI defaults (use X11 by default; tweak if you prefer Wayland)
[ -n "${DISPLAY:-}" ] || export DISPLAY=":0"

# Session bus runtime dir (needed for Electron/Chromium when *running* apps)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR" || true

# Make Flatpak-exported desktop files visible without restarting a session
EXPORTS_SYSTEM="/var/lib/flatpak/exports/share"
EXPORTS_USER="${HOME:-/root}/.local/share/flatpak/exports/share"
case "${XDG_DATA_DIRS:-}" in
  *"$EXPORTS_SYSTEM"*) : ;;
  *) export XDG_DATA_DIRS="${EXPORTS_SYSTEM}:${EXPORTS_USER}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}";;
esac

# RunImage env — extract on /storage (suid OK), persistent overlay, bind storage
export TMPDIR="$TMPDIR_HOST"
export RUNTIME_EXTRACT_AND_RUN=1
export URUNTIME_EXTRACT=1
export RIM_OVERFS_MODE=1
export RIM_KEEP_OVERFS=1
export RIM_OVERFSDIR="$OVERLAYS"
export RIM_OVERFS_ID="$OVERFS_ID"
export RIM_PORTABLE_HOME=1
export RIM_PORTABLE_CONFIG=1
export RIM_ALLOW_ROOT=1
export RIM_BIND="$FLATPAK_DB:/var/lib/flatpak,/storage:/storage"

# One-time safety net (image should have flatpak+dbus+portals already)
BOOTSTRAP='
  set -e
  if ! command -v flatpak >/dev/null 2>&1; then
    pacman -Sy --noconfirm
    pacman -S --noconfirm flatpak xdg-desktop-portal xdg-desktop-portal-gtk dbus || true
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    if command -v bwrap >/dev/null 2>&1; then
      rb="$(readlink -f /usr/bin/bwrap)"; [ -n "$rb" ] && chmod u+s "$rb" || true
    fi
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
    mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR" || true
  fi
'

# Quote/forward args faithfully
ARGS=""
for a in "$@"; do
  q=$(printf "%s" "$a" | sed "s/'/'\\\\''/g")
  ARGS="$ARGS '$q'"
done

# Decide: GUI run vs CLI
first_arg="${1:-}"
if [ "$first_arg" = "run" ]; then
  CMD="dbus-run-session -- flatpak $ARGS"  # GUI apps need a user session bus
else
  CMD="flatpak $ARGS"                      # CLI ops do not
fi

exec "$RI_IMAGE" rim-shell -c "$BOOTSTRAP $CMD"
EOF

chmod +x "$WRAP"

# Ensure /storage/bin is first in PATH for the Rocknix shell
PROFILE="$ROOT/.profile"
if ! grep -qs '/storage/bin' "$PROFILE" 2>/dev/null; then
  echo 'export PATH="/storage/bin:${PATH:-/usr/bin:/bin}"' >> "$PROFILE"
fi

echo
echo "✅ Installed:"
echo "  RunImage : $RI_IMAGE"
echo "  Wrapper  : $WRAP  (takes precedence via PATH)"
echo
echo "Open a NEW shell (or 'source /storage/.profile'), then try:"
echo "  flatpak --version"
echo "  flatpak remotes"
echo "  flatpak install --system -y flathub io.github.peazip.PeaZip"
echo "  flatpak run io.github.peazip.PeaZip"
echo ""
echo ""
echo " * Rockchip SOCs need panfrost mode for many desktop style apps"
echo " * Many Chromium/Electron based apps need --no-sandbox flag to be run as root"
echo " * Some Chromium based apps do better with -disable-gpu --use-gl=swiftshader flags"
echo " * Some apps that refuse to run as root may need their root check / euid modded in their files"
echo ""
echo ""
echo " * To turn off emulationstation to test some apps without using ports launcher"
echo "   run systemctl stop essway / systemctl start essway to restart"

echo " * Visit flathub.org for a full list of apps."
