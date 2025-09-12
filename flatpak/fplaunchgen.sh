#!/bin/bash
# create-flatpak-port.sh — EmulationStation Ports launcher for a Flatpak app (Rocknix)
# Requires: dialog, /storage/bin/flatpak wrapper, gptokeyb; optional: cc (for LD_PRELOAD)
set -euo pipefail

FLATPAK="${FLATPAK:-/storage/bin/flatpak}"
PORTS_DIR="/storage/roms/ports"
GPTK_BIN="${GPTK_BIN:-/usr/bin/gptokeyb}"
FLATPAK_DB="/storage/flatpak"
SHIM_DIR="/storage/ri/flatpak/shims"
SHIM_SO="$SHIM_DIR/libfakeeuid.so"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need dialog
[ -x "$FLATPAK" ] || { echo "Missing flatpak wrapper at $FLATPAK"; exit 1; }
[ -x "$GPTK_BIN" ] || { echo "Missing gptokeyb at $GPTK_BIN"; exit 1; }
mkdir -p "$PORTS_DIR" "$SHIM_DIR"

# List installed apps (tab-separated: application\tname)
mapfile -t RAW < <("$FLATPAK" list --app --columns=application,name 2>/dev/null | sed '/^\s*$/d')
if [ "${#RAW[@]}" -eq 0 ]; then
  dialog --msgbox "No Flatpak apps found.\nInstall one (e.g. PeaZip) and rerun." 8 60
  clear; exit 1
fi

CHOICES=()
while IFS=$'\t' read -r app_id app_name; do
  [ -z "$app_id" ] && continue
  [ -z "$app_name" ] && app_name="$app_id"
  CHOICES+=("$app_id" "$app_name" "off")
done < <(printf '%s\n' "${RAW[@]}")

APP_ID=$(dialog --stdout --radiolist "Select a Flatpak app to wrap:" 20 72 14 "${CHOICES[@]}")
[ -n "${APP_ID:-}" ] || { clear; echo "Cancelled."; exit 0; }

DEFAULT_NAME="${APP_ID##*.}"
FRIENDLY=$(dialog --stdout --inputbox "Friendly launcher name (shown in ES Ports):" 8 60 "$DEFAULT_NAME")
[ -n "${FRIENDLY:-}" ] || { clear; echo "Cancelled."; exit 0; }
STEM="$(echo "$FRIENDLY" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-_' | sed 's/^$/launcher/')"

LAUNCH_SH="$PORTS_DIR/${STEM}.sh"
GPTK_FILE="$PORTS_DIR/${STEM}.gptk"
LOG_FILE="$PORTS_DIR/${STEM}.log"

# Optional scan (root checks/Electron hints)
scan_root_checks() {
  local live
  live="$(readlink -f "$FLATPAK_DB/app/${APP_ID}/current/active/files" 2>/dev/null || true)"
  [ -n "$live" ] && [ -d "$live" ] || return 1
  echo "[scan] Searching $live for root/euid checks and Electron hints…"
  grep -RnaI -E 'geteuid|getuid|process\.geteuid|process\.getuid|isRoot|euid\s*==\s*0|uid\s*==\s*0|EUID|SUDO_USER|electron|chrome' \
    "$live" 2>/dev/null | head -n 200 || true
}
DO_SCAN=$(dialog --stdout --yesno "Scan the app for root checks (geteuid/euid==0) and Electron hints?\n(Results will be logged.)" 10 60; echo $?)
SCAN_HITS=""
if [ "$DO_SCAN" -eq 0 ]; then
  SCAN_HITS="$(scan_root_checks || true)"
fi

# Heuristic preselects
pre_on_no_sandbox=off; pre_on_ozonex11=on; pre_on_inproc_gpu=off; pre_on_no_zygote=off
if printf '%s' "$SCAN_HITS" | grep -qiE 'geteuid|euid|electron'; then
  pre_on_no_sandbox=on
  pre_on_no_zygote=on
fi

# Flags/env checklist  (note the `--`)
readarray -t FLAGSEL < <(dialog --stdout --checklist "Select flags/env for $FRIENDLY" 20 80 14 \
  -- \
  "--no-sandbox"             "Chromium/Electron root quirk"        "$pre_on_no_sandbox" \
  "--disable-gpu"            "Force CPU rendering"                  off \
  "--use-gl=swiftshader"     "Software GL via SwiftShader"          off \
  "--disable-dev-shm-usage"  "Avoid small /dev/shm crashes"         off \
  "--ozone-platform=x11"     "Prefer X11 path"                      "$pre_on_ozonex11" \
  "--in-process-gpu"         "GPU runs in browser proc"             "$pre_on_inproc_gpu" \
  "--no-zygote"              "Chromium tweak for root"              "$pre_on_no_zygote" \
  "--enable-logging"         "Chromium verbose logging"             off \
  "--v=1"                    "Log level 1 (with --enable-logging)"  off \
  "ENV:ELECTRON_OZONE_PLATFORM_HINT=x11" "Electron hint X11"        off \
  "ENV:OZONE_PLATFORM=x11"   "Force Ozone platform var"             off \
  "ENV:LIBGL_ALWAYS_SOFTWARE=1"         "Force llvmpipe"            off \
  "ENV:MESA_LOADER_DRIVER_OVERRIDE=zink" "Try Zink (GL on Vulkan)"  off \
  "ENV:LD_PRELOAD_FAKEEUID"  "Spoof non-root via LD_PRELOAD shim"   off \
)

APP_FLAGS=""
ENV_OPTS=()

# Build APP_FLAGS and ENV_OPTS arrays
for choice in "${FLAGSEL[@]}"; do
  c="${choice%\"}"; c="${c#\"}"   # strip dialog quotes
  if [[ "$c" == ENV:* ]]; then
    case "$c" in
      ENV:LD_PRELOAD_FAKEEUID) ENV_OPTS+=( "--env=LD_PRELOAD=$SHIM_SO" "--env=FAKE_EUID_VALUE=1000" ) ;;
      ENV:*) ENV_OPTS+=( "--env=${c#ENV:}" ) ;;
    esac
  else
    APP_FLAGS+="$c "
  fi
done

# Extra user args (optional)
EXTRA_ARGS=$(dialog --stdout --inputbox "Extra args to pass to app? (optional)" 8 70 "")
[ -n "$EXTRA_ARGS" ] && APP_FLAGS+="$EXTRA_ARGS "


# ---- GPToKeyB profile
PROFILE=$(dialog --stdout --radiolist "Choose a GPToKeyB profile" 15 70 5 \
  "quit-only"    "Only Start+Select to exit mapper" on \
  "kodi-style"   "Back=Esc, Enter=OK, D-Pad nav"    off \
  "manual"       "Prompt for custom keys"           off)
[ -n "${PROFILE:-}" ] || { clear; echo "Cancelled."; exit 0; }

gptk_quit_only() { cat <<'EOF'
[advanced]
exit_hotkey = "SELECT+START"
EOF
}
gptk_kodi_style() { cat <<'EOF'
[buttons]
a = "ENTER"
b = "ESCAPE"
x = ""
y = ""
start = ""
select = ""
l1 = ""
l2 = ""
r1 = ""
r2 = ""
[dpads]
up = "UP"
down = "DOWN"
left = "LEFT"
right = "RIGHT"
[advanced]
exit_hotkey = "SELECT+START"
EOF
}
gptk_manual_prompt() {
  local keys=(back start a b x y l1 l2 r1 r2 up down left right)
  echo "[buttons]"
  for k in "${keys[@]}"; do
    ans=$(dialog --stdout --inputbox "Key for ${k} (empty to skip):" 8 50 "")
    [ -n "$ans" ] && echo "${k} = \"${ans}\"" || true
  done
  echo "[advanced]"
  echo 'exit_hotkey = "SELECT+START"'
}

echo "Writing GPToKeyB → $GPTK_FILE"
case "$PROFILE" in
  quit-only)   gptk_quit_only > "$GPTK_FILE" ;;
  kodi-style)  gptk_kodi_style > "$GPTK_FILE" ;;
  manual)      gptk_manual_prompt > "$GPTK_FILE" ;;
esac



# Ensure LD_PRELOAD shim if requested
need_shim=0
for e in "${ENV_OPTS[@]:-}"; do [[ "$e" == --env=LD_PRELOAD=* ]] && need_shim=1; done
if [ "$need_shim" -eq 1 ] && [ ! -f "$SHIM_SO" ]; then
  if command -v cc >/dev/null 2>&1; then
    cat > "$SHIM_DIR/fakeeuid.c" <<'C'
#define _GNU_SOURCE
#include <unistd.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <sys/types.h>
static uid_t fake_val(){ const char* s=getenv("FAKE_EUID_VALUE"); if(s&&*s) return (uid_t)atoi(s); return (uid_t)1000; }
uid_t geteuid(void){ static uid_t(*real)(void)=NULL; if(!real) real=dlsym(RTLD_NEXT,"geteuid"); const char* off=getenv("DISABLE_FAKE_EUID"); if(off&&*off) return real?real():0; return fake_val(); }
uid_t getuid(void){ static uid_t(*real)(void)=NULL; if(!real) real=dlsym(RTLD_NEXT,"getuid"); const char* off=getenv("DISABLE_FAKE_EUID"); if(off&&*off) return real?real():0; return fake_val(); }
C
    cc -shared -fPIC -ldl -o "$SHIM_SO" "$SHIM_DIR/fakeeuid.c" || { echo "Failed to build shim."; need_shim=0; }
  else
    echo "No C compiler 'cc' found; skipping LD_PRELOAD shim build."
    need_shim=0
    # Drop env opts that referenced the shim
    tmp=(); for e in "${ENV_OPTS[@]}"; do
      case "$e" in --env=LD_PRELOAD=*|--env=FAKE_EUID_VALUE=*) ;; *) tmp+=("$e");; esac
    done; ENV_OPTS=("${tmp[@]}")
  fi
fi

# Serialize ENV_OPTS; if empty, keep it empty (no '' token)
serialize_env_opts() {
  local out=()
  for e in "${ENV_OPTS[@]:-}"; do out+=( "$(printf "%q" "$e")" ); done
  if [ "${#out[@]}" -eq 0 ]; then echo ""; else printf "%s " "${out[@]}"; fi
}
ENV_LINE="$(serialize_env_opts)"

# Keep first 40 lines of scan
[ -n "$SCAN_HITS" ] && printf "%s\n" "$SCAN_HITS" | head -n 40 > "$LOG_FILE.scan" || true

# Write launcher
cat > "$LAUNCH_SH" <<EOF
#!/bin/bash
APP_ID_RAW="${APP_ID}"
FRIENDLY="${FRIENDLY}"
GPTK_FILE="${GPTK_FILE}"
LOG_FILE="${LOG_FILE}"
FLATPAK="${FLATPAK}"
GPTK_BIN="${GPTK_BIN}"
APP_FLAGS="$(printf '%s' "$APP_FLAGS")"
ENV_OPTS_WORDS='${ENV_LINE}'

# Rebuild ENV_OPTS array from words if any
ENV_OPTS=()
if [ -n "\$ENV_OPTS_WORDS" ]; then
  # shellcheck disable=SC2206
  ENV_OPTS=( \$ENV_OPTS_WORDS )
fi

# Sanitize ID
APP_ID="\$(printf '%s\n' "\$APP_ID_RAW" | awk '{print \$1}')"

export GDK_BACKEND=\${GDK_BACKEND:-x11}
export XDG_SESSION_TYPE=\${XDG_SESSION_TYPE:-x11}
export XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/0}
mkdir -p "\$XDG_RUNTIME_DIR" 2>/dev/null || true
chmod 700 "\$XDG_RUNTIME_DIR" 2>/dev/null || true

cd "\$(dirname "\$0")"

if [ -f "\$GPTK_FILE" ] && [ -x "\$GPTK_BIN" ]; then
  "\$GPTK_BIN" "\$FRIENDLY" -c "\$GPTK_FILE" >/dev/null 2>&1 &
  GPTK_PID=\$!
else
  GPTK_PID=""
fi

: > "\$LOG_FILE"
{
  echo "[INFO] Starting flatpak app: \$APP_ID"
  echo "[INFO] Flags: \$APP_FLAGS"
  echo "[INFO] ENV_OPTS: \${ENV_OPTS[*]}"
  echo "[INFO] Time: \$(date)"
} >> "\$LOG_FILE"

set -o pipefail
"\$FLATPAK" run "\${ENV_OPTS[@]}" "\$APP_ID" -- \$APP_FLAGS 2>&1 | tee -a "\$LOG_FILE"
RET=\${PIPESTATUS[0]}

[ -n "\$GPTK_PID" ] && kill "\$GPTK_PID" 2>/dev/null || true
exit \$RET
EOF

chmod +x "$LAUNCH_SH"

MSG="Created:\n\nLauncher: $LAUNCH_SH\nGPToKeyB: $GPTK_FILE"
[ -s "$LOG_FILE.scan" ] && MSG="$MSG\n\n(scan results: $LOG_FILE.scan)"
dialog --msgbox "$MSG" 12 72
clear
echo "✅ Done."
echo "Launcher: $LAUNCH_SH"
echo "GPTK:     $GPTK_FILE"
[ -s "$LOG_FILE.scan" ] && echo "Scan:     $LOG_FILE.scan"
