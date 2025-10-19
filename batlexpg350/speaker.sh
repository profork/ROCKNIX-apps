#!/bin/bash
set -euo pipefail
STATE=/storage/.config/alsa/asound.state

# Small delay so rk817_int is present
sleep 2

# Restore previous good state if any
if [ -f "$STATE" ]; then
  alsactl -f "$STATE" restore || true
fi

# Force speaker route and sane volume (noop if already set)
amixer -c 0 cset name='Playback Mux' 'SPK'  >/dev/null 2>&1 || true
amixer -c 0 sset 'Master' 90% unmute        >/dev/null 2>&1 || true

# Persist for next boots
alsactl -f "$STATE" store || true

echo "[audio-kick] rk817 set to SPK + Master unmuted (state: $STATE)"
