#!/bin/bash
# install-g350-speaker-fix.sh
# Always installs to /storage/.config/autostart/speaker.sh (dir layout),
# marks it executable, and executes it now.

set -euo pipefail

AUTOSTART_DIR="/storage/.config/autostart"
SPEAKER_SH="${AUTOSTART_DIR}/speaker.sh"
FORCE=0

# --- args ---
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

# --- ensure directory layout ---
mkdir -p "${AUTOSTART_DIR}"

# --- write speaker.sh (create or overwrite with --force) ---
if [[ -f "${SPEAKER_SH}" && "${FORCE}" -eq 0 ]]; then
  echo "[install] ${SPEAKER_SH} exists; not overwriting (use --force to replace)."
else
  cat > "${SPEAKER_SH}" <<'EOF'
#!/bin/bash
# G350 / RK817 speaker route kick for Rocknix/Batocera

STATE=/storage/.config/alsa/asound.state

# small delay to ensure rk817_int is up
sleep 2

# restore if present
if [ -f "$STATE" ]; then
  alsactl -f "$STATE" restore || true
fi

# force speaker route + sane volume
amixer -c 0 cset name='Playback Mux' 'SPK'  >/dev/null 2>&1 || true
amixer -c 0 sset 'Master' 90% unmute        >/dev/null 2>&1 || true

# persist for next boots
alsactl -f "$STATE" store || true

echo "[audio-kick] rk817 set to SPK + Master unmuted (state: $STATE)"
EOF
  echo "[install] Wrote ${SPEAKER_SH}"
fi

# --- ensure executable ---
chmod +x "${SPEAKER_SH}"
echo "[install] Marked ${SPEAKER_SH} executable"

# --- run now for current session ---
bash "${SPEAKER_SH}"

echo "[done] Installed to ${SPEAKER_SH} and executed for this session."
