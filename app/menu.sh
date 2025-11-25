#!/usr/bin/env bash

# Colors for animation
RED='\e[0;31m'
YELLOW='\e[1;33m'
NC='\e[0m' # No Color

# Function to display animated text faster
animate_text() {
    local text="$1"
    echo -e "$text"
    sleep 0.
}

clear

# Display Warning Message (kept exactly like your template vibe)
animate_text "${YELLOW}⚠️  Important Notice ⚠️${NC}"
animate_text "${YELLOW}The apps on this repository are provided AS-IS.${NC}"

animate_text "${YELLOW}Use at your own risk.${NC}"

# Reset color
echo -e "${NC}"

sleep 5

# ---- deps / arch ----
set -euo pipefail
architecture="$(uname -m)"
case "$architecture" in aarch64) ;; *) echo "Unsupported CPU arch: $architecture"; exit 1;; esac
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }
need dialog; { command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; } || { echo "Missing: curl or wget"; exit 1; }

# ---- Rocknix Apps (label -> installer one-liner) ----
# These are the same set we discussed for Rocknix.
declare -A RUN
RUN=(
  [1]="echo 'Desktop Mode (RunImage XFCE)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/desktop/runimage-desktop.sh | bash"
  [2]="echo 'Steam (RunImage, experimental)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/steam.sh | bash"
  [3]="echo 'Caja + Engrampa...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/caja/caja-install.sh | bash"
  [4]="echo 'VacuumTube (YouTube TV UI)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/vacuumtube.sh | bash"
  [5]="echo 'Greenlight...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/greenlight.sh | bash"
  #[6]="echo 'Chiaki (PS4/PS5)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/chiaki/chiaki.sh | bash"
  [6]="echo 'Firefox...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/firefox.sh | bash"
  [7]="echo 'Brave (AppImage)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/brave/brave.sh | bash"
  [8]="echo 'Ungoogled-Chromium (AppImage)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/ugc.sh | bash"
  [9]="echo 'LibreWolf + Leanback...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/librewolf/librewolf.sh | bash"
  [10]="echo 'Chromium (Alpine chroot)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/chromium/chromium.sh | bash"
  [11]="echo 'Kodi (RunImage)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/kodi/kodi-installer.sh | bash"
  [12]="echo 'ES Carbon Theme...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/es-carbon.sh | bash"
  [13]="echo 'ES Music Pack...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/music.sh | bash"
  [14]="echo 'Free Homebrew ROM Pack...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/freebatroms.sh | bash"
  [15]="echo 'Flatpak wrapper (RunImage)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/flatpak/flatpak.sh | bash"
  [16]="echo 'Soar (pkg-forge)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/soar.sh | bash"
  [17]="echo 'PKGX (CLI tool mgr)...'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/pkgx/pkgx.sh | bash"
  [18]="echo 'ROCKNIX-WINE Setup tool...'; curl -L https://github.com/profork/Rocknix-WINE/raw/main/wine_setup.sh | bash"
  [19]="echo 'JeodC Pharos App (External Portmaster apps)'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/pharos.sh | bash"
  [20]="echo 'BatleXP G350 Audio Fix'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/batlexpg350/install_speaker_fix.sh | bash"
  [21]="echo 'pip & piptools'; curl -L https://github.com/profork/ROCKNIX-apps/raw/main/piptools.sh | bash"
  [99]="echo 'Exiting...'; exit 0"
)

# ---- Options list (numbers + labels, like your template) ----
OPTIONS=(
  "1"  "ARCH XFCE DESKTOP MODE - RUNIMAGE"
  "2"  "Steam [RunImage/Experimental]"
  "3"  "Caja + Engrampa (File Manager + Archiver)"
  "4"  "VacuumTube (YouTube TV UI)"
  "5"  "Greenlight (Xbox/Xcloud)"
  #"6"  "Chiaki (PS4/PS5 Remote Play)"
  "6"  "Firefox"
  "7"  "Brave (AppImage)"
  "8"  "Ungoogled-Chromium (AppImage)"
  "9" "LibreWolf + Leanback TV Profile"
  "10" "Chromium (Alpine chroot)"
  "11" "Kodi (RunImage)"
  "12" "ES Carbon Theme"
  "13" "ES Music Pack"
  "14" "Free Homebrew ROM Pack"
  "15" "Flatpak wrapper (RunImage)"
  "16" "Soar (pkg-forge)"
  "17" "PKGX (CLI tool mgr)"
  "18" "Wine Setup Tool"
  "19" "JeodC Pharos App (External Portmaster repositories)"
  "20" "BatleXP G350 Audio fix"
  "21" "PIP tools"
  "99" "Exit"
)

# ---- Show menu ONCE (single-select), run, then exit ----
CHOICE=$(dialog --clear --backtitle "Profork ROCKNIX-Apps" \
                --title "ROCKNIX-Apps" \
                --menu "Choose one item to install:" 25 120 18 \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty) || { echo "Cancelled."; exit 1; }

clear
if [[ -n "${RUN[$CHOICE]+set}" ]]; then
  eval "${RUN[$CHOICE]}"
else
  echo "No valid option selected."
fi

exit 0
