#!/bin/bash
# runimage_install_and_port_launcher_rocknix.sh
# Rocknix: installs RunImage (correct arch), sets up TWO Ports launchers:
#  1) RunImage Desktop Xephyr (classic Xephyr/X11 flow)
#  2) RunImage Desktop Sway   (flatpak-style, Wayland/Sway & Flatpak compatible)
#
# OverlayFS (FUSE) is preferred; we fall back to persistent "unpacked" mode.

clear
echo "RUNIMAGE developed by VHSGUNZO"
sleep 6
clear

set -euo pipefail

# --- Detect arch & choose asset ---
ARCH="$(uname -m)"
case "${ARCH}" in
  aarch64|arm64) ASSET="runimage-aarch64" ;;
  x86_64|amd64)  ASSET="runimage-x86_64"  ;;
  *) echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac

# --- Paths (Rocknix) ---
BIN_URL="https://github.com/VHSgunzo/runimage/releases/download/continuous/${ASSET}"
DEST_BASE="/storage/system/runimage"
BIN_PATH="${DEST_BASE}/runimage"
OVERLAY_DIR="${DEST_BASE}/overlays"
CACHE_DIR="${DEST_BASE}/cache"
RUNTIME_DIR="${DEST_BASE}/runtime"   # persistent extracted rootfs if FUSE unavailable
PORTS_DIR="/storage/roms/ports"
LAUNCHER_XEPHYR="${PORTS_DIR}/RunImage Desktop Xephyr.sh"
LAUNCHER_SWAY="${PORTS_DIR}/RunImage Desktop Sway.sh"
README="${DEST_BASE}/README.txt"

OVERFS_ID="rocknix-xfce"
DISPLAY_VAR=":0.0"

echo "[*] Creating directories..."
mkdir -p "${DEST_BASE}" "${OVERLAY_DIR}" "${CACHE_DIR}" "${RUNTIME_DIR}" "${PORTS_DIR}"

echo "[*] Downloading ${ASSET} -> ${BIN_PATH}"
curl -L --fail --retry 3 --progress-bar "${BIN_URL}" -o "${BIN_PATH}"
chmod +x "${BIN_PATH}"

# Helper: ensure FUSE node/module if possible
cat > "${DEST_BASE}/ensure_fuse.sh" <<'EOSH'
#!/bin/sh
set -eu
if [ ! -e /dev/fuse ]; then
  modprobe fuse 2>/dev/null || true
  [ -e /dev/fuse ] || mknod /dev/fuse -m 0666 c 10 229 || true
fi
EOSH
chmod +x "${DEST_BASE}/ensure_fuse.sh"

###############################################################################
# Launcher 1: Xephyr/X11 (classic rim-desktop)
###############################################################################
echo "[*] Writing Ports launcher (Xephyr) -> ${LAUNCHER_XEPHYR}"
cat > "${LAUNCHER_XEPHYR}" <<'EOF'
#!/bin/bash
# RunImage Desktop Xephyr (classic X11 via rim-desktop)
set -euo pipefail

DEST_BASE="/storage/system/runimage"
BIN_PATH="${DEST_BASE}/runimage"
OVERLAY_DIR="${DEST_BASE}/overlays"
CACHE_DIR="${DEST_BASE}/cache"
RUNTIME_DIR="${DEST_BASE}/runtime"

OVERFS_ID="rocknix-xfce"
DISPLAY_VAR=":0.0"

ensure_fuse() { "${DEST_BASE}/ensure_fuse.sh" || true; }

launch_overlay() {
  RIM_OVERFS_ID="${OVERFS_ID}" \
  RIM_KEEP_OVERFS=1 \
  RIM_UNSHARE_HOME=1 \
  RIM_BIND="/storage:/storage" \
  RIM_OVERFSDIR="${OVERLAY_DIR}" \
  RIM_CACHEDIR="${CACHE_DIR}" \
  RIM_ALLOW_ROOT=1 DISPLAY="${DISPLAY_VAR}" \
  "${BIN_PATH}" rim-desktop
}

launch_unpacked() {
  # No FUSE: extract-and-run into persistent dir so changes survive reboots.
  URUNTIME_TARGET_DIR="${RUNTIME_DIR}" \
  TMPDIR="${RUNTIME_DIR}" \
  RUNTIME_EXTRACT_AND_RUN=1 \
  NO_CLEANUP=1 \
  RIM_UNSHARE_HOME=1 \
  RIM_BIND="/storage:/storage" \
  RIM_ALLOW_ROOT=1 DISPLAY="${DISPLAY_VAR}" \
  "${BIN_PATH}" rim-desktop
}

mkdir -p "${OVERLAY_DIR}" "${CACHE_DIR}" "${RUNTIME_DIR}"

# Try overlay first; on failure fall back to unpacked mode.
ensure_fuse
set +e
launch_overlay
rc=$?
set -e
if [ $rc -ne 0 ]; then
  echo "[!] Overlay launch failed (likely FUSE unavailable). Falling back to unpacked mode..."
  launch_unpacked
fi
EOF
chmod +x "${LAUNCHER_XEPHYR}"

###############################################################################
# Launcher 2: Sway/Wayland-friendly (flatpak-style rim-shell wrapper)
# - Works nicely under Sway/Wayland
# - Good compatibility with Flatpak apps inside the image
###############################################################################
echo "[*] Writing Ports launcher (Sway/Flatpak) -> ${LAUNCHER_SWAY}"
cat > "${LAUNCHER_SWAY}" <<'EOF'
#!/bin/bash
# RunImage Desktop Sway (Flatpak-compatible, Wayland-friendly)
set -euo pipefail

DEST_BASE="/storage/system/runimage"
BIN_PATH="${DEST_BASE}/runimage"
OVERLAY_DIR="${DEST_BASE}/overlays"
CACHE_DIR="${DEST_BASE}/cache"
RUNTIME_DIR="${DEST_BASE}/runtime"
TMPDIR_HOST="${DEST_BASE}/tmp"

OVERFS_ID="rocknix-xfce"
DISPLAY_VAR=":0.0"

# What to start inside the image:
# - Full desktop:  DESKTOP_CMD="dbus-run-session -- startxfce4"
# - Just a panel:  DESKTOP_CMD="dbus-run-session -- xfce4-panel"
# - Single app:    DESKTOP_CMD="dbus-run-session -- xterm"
DESKTOP_CMD="dbus-run-session -- startxfce4"

ensure_fuse() { "${DEST_BASE}/ensure_fuse.sh" || true; }

# Keep overlays around (like typical Flatpak workflows)
export RIM_OVERFS_MODE=1
export RIM_KEEP_OVERFS=1

# Host dirs used by RunImage
mkdir -p "${OVERLAY_DIR}" "${CACHE_DIR}" "${RUNTIME_DIR}" "${TMPDIR_HOST}"

# Common env (NO /proc,/sys,/dev binds!)
COMMON_ENV="
  DISPLAY=${DISPLAY_VAR}
  RIM_UNSHARE_HOME=1
  RIM_ALLOW_ROOT=1
  RIM_BIND=/storage:/storage
  TMPDIR=${TMPDIR_HOST}
"

# Bootstrap inside the image (suid bwrap + XDG_RUNTIME_DIR)
BOOTSTRAP='
  set -e
  if command -v bwrap >/dev/null 2>&1; then
    rb="$(readlink -f /usr/bin/bwrap || true)"
    if [ -n "$rb" ] && [ -f "$rb" ]; then chmod u+s "$rb" || true; fi
  fi
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/0}"
  mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR" || true
'

launch_overlay() {
  # Overlay-backed session (fast path)
  env \
    RIM_OVERFS_ID="${OVERFS_ID}" \
    RIM_OVERFSDIR="${OVERLAY_DIR}" \
    RIM_CACHEDIR="${CACHE_DIR}" \
    ${COMMON_ENV} \
    "${BIN_PATH}" rim-shell -c "$BOOTSTRAP exec ${DESKTOP_CMD}"
}

launch_unpacked() {
  # Fallback: extract-and-run into persistent dir so changes survive reboots
  env \
    URUNTIME_TARGET_DIR="${RUNTIME_DIR}" \
    RUNTIME_EXTRACT_AND_RUN=1 \
    NO_CLEANUP=1 \
    ${COMMON_ENV} \
    "${BIN_PATH}" rim-shell -c "$BOOTSTRAP exec ${DESKTOP_CMD}"
}

ensure_fuse
set +e
launch_overlay
rc=$?
set -e
if [ $rc -ne 0 ]; then
  echo "[!] Overlay launch failed (likely FUSE unavailable). Falling back to unpacked mode..."
  launch_unpacked
fi
EOF
chmod +x "${LAUNCHER_SWAY}"

# --- README / Info box ---
cat > "${README}" <<'EOF'
RunImage Desktop (Rocknix) installed!

Launchers created (EmulationStation → Ports):
• RunImage Desktop Xephyr — classic Xephyr/X11 session
• RunImage Desktop Sway — Wayland/Sway and Flatpak-compatible

Bindings:
• /storage is mounted inside the session at the same path (/storage).

Tips:
• Pacman is available inside the desktop.
• Chromium-based apps (Chromium/Brave/Electron) as root need:
    --no-sandbox
  Examples:
    chromium --no-sandbox
    brave --no-sandbox
    
Overlay maintenance:
  /storage/system/runimage/runimage rim-ofsls
  /storage/system/runimage/runimage rim-ofsrm rocknix-xfce

If overlay fails with “failed to utilize FUSE”:
  - Make sure you're using the correct arch build (aarch64 on ARM).
  - Ensure /dev/fuse exists (the launcher attempts to create it).


EOF

INFO_TEXT="$(cat "${README}")"
if command -v dialog >/dev/null 2>&1; then
  dialog --title "RunImage Desktop (Rocknix)" --msgbox "${INFO_TEXT}" 26 90 || true
else
  echo
  echo "================= RunImage Desktop (Rocknix) ================="
  echo "${INFO_TEXT}"
  echo "A copy of this info is at: ${README}"
  echo "=============================================================="
  echo
fi

clear
echo "[✓] Done."
echo "Binary:   ${BIN_PATH}"
echo "Overlay:  ${OVERLAY_DIR}"
echo "Cache:    ${CACHE_DIR}"
echo "Runtime:  ${RUNTIME_DIR}"
echo "Launcher (Xephyr): ${LAUNCHER_XEPHYR}"
echo "Launcher (Sway):   ${LAUNCHER_SWAY}"
echo "README:   ${README}"
echo
echo "FIRST LAUNCH CAN TAKE A WHILE (especially on microSD / slower media)."
echo "Desktop packages may install on first run; several minutes is normal."
echo "Launch via EmulationStation: Ports → “RunImage Desktop Xephyr/Sway” (Update Gamelist if needed)."
echo
