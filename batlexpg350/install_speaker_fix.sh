#!/bin/bash
# install-g350-speaker-fix.sh
# Installs a G350/RK817 speaker route fix into /storage/.config/autostart,
# makes it executable, and executes the fix now.

set -euo pipefail

TARGET="/storage/.config/autostart"
MARK_BEGIN="# >>> G350_SPEAKER_FIX_BEGIN"
MARK_END="# <<< G350_SPEAKER_FIX_END"

mkdir -p /storage/.config

# Create file if missing
if [ ! -f "$TARGET" ]; then
  echo "#!/bin/bash" > "$TARGET"
  echo "" >> "$TARGET"
fi

# If our block isn't present, append it
if ! grep -q "$MARK_BEGIN" "$TARGET"; then
  cat >> "$TARGET" <<'EOF'
# >>> G350_SPEAKER_FIX_BEGIN
(
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
  # persist
  alsactl -f "$STATE" store || true
  echo "[audio-kick] rk817 set to SPK + Master unmuted (state: $STATE)"
) &
# <<< G350_SPEAKER_FIX_END
EOF
  echo "[install] Appended speaker-fix block to $TARGET"
else
  echo "[install] Speaker-fix block already present in $TARGET"
fi

# Ensure executable
chmod +x "$TARGET"
echo "[install] Marked $TARGET executable"

# Run the fix now for current session (same commands as in autostart)
STATE=/storage/.config/alsa/asound.state
sleep 2
if [ -f "$STATE" ]; then
  alsactl -f "$STATE" restore || true
fi
amixer -c 0 cset name='Playback Mux' 'SPK'  >/dev/null 2>&1 || true
amixer -c 0 sset 'Master' 90% unmute        >/dev/null 2>&1 || true
alsactl -f "$STATE" store || true
echo "[run-now] rk817 set to SPK + Master unmuted (state: $STATE)"

echo "[done] Installed to $TARGET and executed for this session."
