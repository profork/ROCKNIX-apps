#!/bin/bash
# Fetch a curated set of free ROMs into /storage/roms/<system>
# Dependencies: wget, mkdir
# Behavior: skips existing files; set OVERWRITE=1 to force re-downloads.

set -euo pipefail

ROMROOT="/storage/roms"
OVERWRITE="${OVERWRITE:-0}"

# download URL | subdir | filename
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

download() {
  local url="$1" out="$2"
  if [[ -f "$out" && "$OVERWRITE" != "1" ]]; then
    echo "✔ Exists, skipping: $out"
    return 0
  fi
  echo "↓ Downloading: $out"
  # -q quiet other output, but show a progress bar
  wget -q --show-progress -O "$out".partial "$url"
  mv -f "$out".partial "$out"
  echo "✔ Saved: $out"
}

echo "=== Installing free ROMs to $ROMROOT ==="
for line in "${ITEMS[@]}"; do
  # skip comments / blanks
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  IFS='|' read -r url subdir filename <<<"$line"

  destdir="$ROMROOT/$subdir"
  mkdir -p "$destdir"
  dest="$destdir/$filename"

  download "$url" "$dest"
done

echo "=== Done. ==="
echo "Tip: set OVERWRITE=1 to force re-downloads, e.g.: OVERWRITE=1 bash get_free_roms.sh"
