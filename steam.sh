#!/bin/bash
# install-steam-runimage.sh — Rocknix: install Steam RunImage into Ports
# - Downloads split 7z parts
# - Extracts a single file named "runimage"
# - Places it at /storage/roms/ports/steam/runimage (executable)


clear
echo "Installing Steam RunImage from ROCKNIX-apps repo..."
sleep 3
clear
echo "Thanks to VHSgunzo for Runimage!"
echo "Thanks to Mash0star for Making the Steam Runimage!"
sleep 5

# - Creates ensure_fuse.sh + a launcher script for EmulationStation Ports

set -euo pipefail

# ===== Config =====
PART1_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/runimage-steam.7z.001"
PART2_URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/runimage-steam.7z.002"

PORTS_DIR="/storage/roms/ports"
STEAM_DIR="${PORTS_DIR}/steam"
DEST_BASE="/storage/system/runimage"             # matches your launcher expectation
BIN_PATH="${STEAM_DIR}/runimage"                 # where the RunImage binary must live
OVERLAY_DIR="${DEST_BASE}/overlays"
CACHE_DIR="${DEST_BASE}/cache"
RUNTIME_DIR="${DEST_BASE}/runtime"
LAUNCHER="${PORTS_DIR}/Steam.sh"
ENSURE_FUSE="${DEST_BASE}/ensure_fuse.sh"

# ===== Prep =====
echo "➤ Preparing folders…"
mkdir -p "${STEAM_DIR}" "${DEST_BASE}" "${OVERLAY_DIR}" "${CACHE_DIR}" "${RUNTIME_DIR}"

TMPDIR="/storage/system/tmp/install-steam-runimage.$$"
mkdir -p "${TMPDIR}"

cleanup() { rm -rf "${TMPDIR}" || true; }
trap cleanup EXIT

# ===== Checks =====
if ! command -v 7z >/dev/null 2>&1 && ! command -v 7za >/dev/null 2>&1; then
  echo "ERROR: 7z is required on Rocknix (package provides '7z' or '7za')."
  exit 1
fi

_7Z="$(command -v 7z || command -v 7za)"

# ===== Download =====
echo "➤ Downloading Steam RunImage parts…"
wget -c --tries=10 --retry-connrefused -O "${TMPDIR}/runimage-steam.7z.001" "${PART1_URL}"
wget -c --tries=10 --retry-connrefused -O "${TMPDIR}/runimage-steam.7z.002" "${PART2_URL}"

# ===== Extract (produces a single file named 'runimage') =====
echo "➤ Extracting…"
( cd "${TMPDIR}" && "${_7Z}" x -y "runimage-steam.7z.001" )

if [[ ! -f "${TMPDIR}/runimage" ]]; then
  echo "ERROR: Extraction did not produce 'runimage'."
  exit 2
fi

# ===== Install RunImage =====
echo "➤ Installing RunImage to ${BIN_PATH}…"
mv -f "${TMPDIR}/runimage" "${BIN_PATH}"
chmod +x "${BIN_PATH}"

# ===== ensure_fuse.sh =====
echo "➤ Writing ${ENSURE_FUSE}…"
cat > "${ENSURE_FUSE}" <<'EOF'
#!/bin/sh
# Minimal FUSE helper for Rocknix RunImage overlay usage
set -eu
if [ -e /dev/fuse ]; then
  exit 0
fi
# Try to load fuse module if available
if command -v modprobe >/dev/null 2>&1; then
  modprobe fuse 2>/dev/null || true
fi
# Warn if still missing
if [ ! -e /dev/fuse ]; then
  echo "[WARN] /dev/fuse not available; overlay mode may fail (fallback will be used)."
fi
exit 0
EOF
chmod +x "${ENSURE_FUSE}"

# ===== Launcher =====
echo "➤ Creating launcher ${LAUNCHER}…"
cat > "${LAUNCHER}" <<'EOF'
#!/bin/bash
set -euo pipefail

DEST_BASE="/storage/system/runimage"
BIN_PATH="/storage/roms/ports/steam/runimage"
OVERLAY_DIR="${DEST_BASE}/overlays"
CACHE_DIR="${DEST_BASE}/cache"
RUNTIME_DIR="${DEST_BASE}/runtime"

OVERFS_ID="rocknix-steam"
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
  "${BIN_PATH}" FEXBash /root/.local/share/Steam/steam.sh
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
  "${BIN_PATH}" FEXBash /root/.local/share/Steam/steam.sh
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
chmod +x "${LAUNCHER}"

echo ""
echo "✅ Steam RunImage installed."
echo "   • RunImage: ${BIN_PATH}"
echo "   • ensure_fuse: ${ENSURE_FUSE}"
echo "   • Launcher: ${LAUNCHER}"
echo ""
echo "🎮 In EmulationStation, refresh the Ports list to see 'Steam'."
echo "ℹ️ Overlay mode prefers /dev/fuse; without it, the launcher auto-falls back to unpacked mode."
