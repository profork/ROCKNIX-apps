#!/bin/bash
# Free ROM installer for Rocknix/Batocera-style layouts.
# - Installs Batocera + REG-Linux freebies (direct raw URLs)
# - Installs EmuDeck homebrew by downloading the repo zip once and copying .zip ROMs into /storage/roms/<system>
#
# Deps: wget, unzip, find, mkdir, cp
# Env:
#   OVERWRITE=1   force re-downloads / overwrite existing files (default: 0)
#   EMUDECK=1     enable EmuDeck homebrew fetch (default: 1)

set -euo pipefail

ROMROOT="/storage/roms"
TMPDIR="/tmp"
OVERWRITE="${OVERWRITE:-0}"
EMUDECK="${EMUDECK:-1}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need wget
need unzip
need find

log() { echo -e "$*"; }

download() {
  local url="$1" out="$2"
  if [[ -f "$out" && "$OVERWRITE" != "1" ]]; then
    log "✔ Exists, skipping: $out"
    return 0
  fi
  mkdir -p "$(dirname "$out")"
  wget -q --no-check-certificate --retry-connrefused -O "$out".partial "$url"
  mv -f "$out".partial "$out"
  log "✔ Saved: $out"
}

# -----------------------------
# Static freebies (Batocera/REG-Linux)
# -----------------------------
readarray -t ITEMS <<'EOF'
# --- Batocera sources ---
https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/package/batocera/emulationstation/batocera-es-system/roms/nes/2048%20(tsone).nes|nes|2048 (tsone).nes
https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/package/batocera/emulationstation/batocera-es-system/roms/megadrive/Old-Towers.bin|megadrive|Old-Towers.bin
https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/package/batocera/emulationstation/batocera-es-system/roms/gba/SpaceTwins.gba|gba|SpaceTwins.gba
https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/package/batocera/emulationstation/batocera-es-system/roms/pcengine/Reflectron%20(aetherbyte).pce|pcengine|Reflectron (aetherbyte).pce
https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/package/batocera/emulationstation/batocera-es-system/roms/snes/DonkeyKongClassic%20(Shiru).smc|snes|DonkeyKongClassic (Shiru).smc
https://raw.githubusercontent.com/batocera-linux/batocera.linux/master/package/batocera/emulationstation/batocera-es-system/roms/c64/fix_it_felix_64.d64|c64|fix_it_felix_64.d64

# --- REG-Linux sources ---
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/c64/Relentless64.d64|c64|Relentless64.d64
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/c64/Showdown.d64|c64|Showdown.d64
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/gba/Anguna.gba|gba|Anguna.gba
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/gbc/Petris.gbc|gbc|Petris.gbc
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/pcengine/Dinoforce.pce|pcengine|Dinoforce.pce
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/snes/Dottie%20Flowers%20(v1.1).sfc|snes|Dottie Flowers (v1.1).sfc
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/snes/Super%20Boss%20Gaiden%20(v1.2).sfc|snes|Super Boss Gaiden (v1.2).sfc
https://raw.githubusercontent.com/REG-Linux/REG-Linux/master/package/emulationstation/es-system/roms/atari2600/Amoeba%20Jump%20v1.3%20NTSC.bin|atari2600|Amoeba Jump v1.3 NTSC.bin
EOF

log "=== Installing Batocera/REG-Linux freebies to $ROMROOT ==="
for line in "${ITEMS[@]}"; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  IFS='|' read -r url subdir filename <<<"$line"
  destdir="$ROMROOT/$subdir"
  mkdir -p "$destdir"
  download "$url" "$destdir/$filename"
done

# -----------------------------
# EmuDeck homebrew (keep ROMs zipped)
# -----------------------------
if [[ "$EMUDECK" == "1" ]]; then
  EMUDECK_URL="https://github.com/EmuDeck/emudeck-homebrew/archive/refs/heads/main.zip"
  EMUDECK_ZIP="$TMPDIR/emudeck-homebrew.zip"
  EMUDECK_DIR="$TMPDIR/emudeck-homebrew"

  download "$EMUDECK_URL" "$EMUDECK_ZIP"
  rm -rf "$EMUDECK_DIR"
  mkdir -p "$EMUDECK_DIR"
  unzip -q "$EMUDECK_ZIP" -d "$EMUDECK_DIR"
  ROOT_EXPANDED="$(find "$EMUDECK_DIR" -maxdepth 1 -type d -name 'emudeck-homebrew-*' | head -n1)"

  # Map repo folder → ES system folder
  map_system() {
    local s="${1,,}"
    case "$s" in
      genesis|md|megadrive) echo "megadrive" ;;
      pce|tg16|pcengine)    echo "pcengine" ;;
      mastersystem|sms)     echo "mastersystem" ;;
      snes|sfc)             echo "snes" ;;
      nes|famicom)          echo "nes" ;;
      gb)                   echo "gb" ;;
      gbc)                  echo "gbc" ;;
      gba)                  echo "gba" ;;
      gamegear|gg)          echo "gamegear" ;;
      atari2600|a2600)      echo "atari2600" ;;
      c64|commodore64)      echo "c64" ;;
      *)                    echo "$s" ;;
    esac
  }

  # Ignore by pattern (case/space/underscore/dash insensitive)
  IGNORE_PATTERNS=(
    "alter_ego"         # Alter_Ego.zip variants
    "rem"               # REM.zip (short; adjust if too broad)
    "petrophobia"       # Petrophobia.zip
    "anguna"            # any Anguna zip if present (duplicate)
    "wingwarriors"      # WingWarriors.zip or Wing Warriors.zip
    "brokencircle"      # BrokenCircle.zip / Broken Circle.zip
    "abbaye"            # Abbaye_des_Morts.zip variants
    "lethalwedding"     #
  )

  normalize() {
    # lower-case and strip all non-alphanumeric
    local s="${1,,}"
    s="${s// /}"
    s="${s//_/}"
    s="${s//-/}"
    s="${s//./}"
    s="${s//(/}"
    s="${s//)/}"
    s="${s//\'/}"
    s="${s//,/}"
    echo "$s"
  }

  should_ignore() {
    local base_norm; base_norm="$(normalize "$1")"
    for pat in "${IGNORE_PATTERNS[@]}"; do
      local pat_norm; pat_norm="$(normalize "$pat")"
      if [[ "$base_norm" == *"$pat_norm"* ]]; then
        return 0
      fi
    done
    return 1
  }

  # Copy zipped ROMs quietly
  while IFS= read -r -d '' sysdir; do
    sysname="$(basename "$sysdir")"
    [[ "$sysname" == "downloaded_media" ]] && continue
    target="$(map_system "$sysname")"
    mkdir -p "$ROMROOT/$target"

    while IFS= read -r -d '' zipfile; do
      base="$(basename "$zipfile")"
      if should_ignore "$base"; then
        continue
      fi
      dest="$ROMROOT/$target/$base"
      if [[ -f "$dest" && "$OVERWRITE" != "1" ]]; then
        continue
      fi
      cp -f "$zipfile" "$dest"
    done < <(find "$sysdir" -maxdepth 1 -type f -name '*.zip' -print0)

  done < <(find "$ROOT_EXPANDED" -maxdepth 1 -mindepth 1 -type d -print0)
fi

log "=== Done. ==="
log "Tip: set OVERWRITE=1 to force overwrites; set EMUDECK=0 to skip EmuDeck."
