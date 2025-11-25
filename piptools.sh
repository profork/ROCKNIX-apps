#!/bin/bash
# pip-toolbox.sh - Interactive pip tool installer for Rocknix/Batocera-style systems
# Requires: bash, python3, dialog, curl (for some tools to be useful later)

set -u

########################################
# 0. Sanity checks
########################################

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 not found in PATH."
  exit 1
fi

if ! command -v dialog >/dev/null 2>&1; then
  echo "Error: 'dialog' not found. Please install/enable 'dialog' first."
  exit 1
fi

PYTHON=python3

########################################
# 1. Ensure pip exists
########################################

echo "==> Ensuring pip is available for python3 (this may take a moment)..."

# Try ensurepip – ignore errors if already set up or not supported
if ! "$PYTHON" -m ensurepip --upgrade 2>/dev/null; then
  echo "   (ensurepip failed or already done; continuing)"
fi

########################################
# 2. Determine user base & bin dir
########################################

USER_BASE=$("$PYTHON" -m site --user-base 2>/dev/null || echo "$HOME/.local")
BIN_DIR="$USER_BASE/bin"

mkdir -p "$BIN_DIR"

echo "   Python user base: $USER_BASE"
echo "   User bin dir:     $BIN_DIR"

########################################
# 3. Make sure BIN_DIR is on PATH
########################################

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "   $BIN_DIR already in PATH."
    ;;
  *)
    echo "   Adding $BIN_DIR to PATH for this session."
    export PATH="$PATH:$BIN_DIR"
    ;;
esac

# Persist PATH in startup files
add_path_line='export PATH="$PATH:'"$BIN_DIR"'"'

update_rc_file() {
  local rc="$1"
  [ -e "$rc" ] || touch "$rc"
  if ! grep -F "$BIN_DIR" "$rc" >/dev/null 2>&1; then
    echo "$add_path_line" >> "$rc"
    echo "   Added PATH update to $rc"
  fi
}

echo "==> Making PATH change persistent..."
update_rc_file "$HOME/.profile"
update_rc_file "$HOME/.bashrc"

########################################
# 4. Define pip tools & descriptions
########################################

# Format: TAG "Description" initial_state
CHOICES=(
  gdown           "Google Drive downloader (handles confirm tokens)" off
  yt-dlp          "YouTube/media downloader (successor to youtube-dl)" off
  you-get         "Simple media downloader for various sites" off
  patool          "Archive extractor front-end (many formats)" off
  zipfile-deflate64 "Support for weird ZIP Deflate64 archives" off
  glances         "Terminal system monitor (CPU/RAM/Net etc.)" off
  psutil          "Python system info (for your own scripts)" off
  sh              "Friendly subprocess wrapper for Python scripts" off
  rich            "Pretty terminal UI / progress bars / colors" off
  pygments        "Syntax highlighting (logs, code, etc.)" off
  watchdog        "Filesystem event monitor (auto-rescan ROM dirs)" off
  python-magic    "File type detection based on content" off
  csvkit          "Power tools for CSV ROM lists / metadata" off
  tabulate        "Pretty table output in terminal" off
  speedtest-cli   "CLI speedtest.net network tester" off
  pygame          "SDL-based game / graphics library for Python" off
)

########################################
# 5. Show dialog checklist
########################################

HEIGHT=25
WIDTH=78
MENU_HEIGHT=17

CHOICE_TEXT=$(
  dialog \
    --backtitle "Rocknix Python Toolbox Installer" \
    --title "Select pip tools to install/upgrade" \
    --separate-output \
    --checklist "Use SPACE to select, ENTER to install:" \
    "$HEIGHT" "$WIDTH" "$MENU_HEIGHT" \
    "${CHOICES[@]}" \
    2>&1 >/dev/tty
)

RET=$?
clear

if [ "$RET" -ne 0 ]; then
  echo "No tools selected (or dialog cancelled). Nothing to do."
  exit 0
fi

if [ -z "$CHOICE_TEXT" ]; then
  echo "No tools selected. Nothing to do."
  exit 0
fi

########################################
# 6. Install selected tools with pip
########################################

echo "==> Installing selected tools via pip..."
echo

# Fully disable bytecode compilation to avoid pyc_path AssertionError
export PIP_NO_COMPILE=1

for PKG in $CHOICE_TEXT; do
  # dialog returns values quoted; strip quotes if present
  PKG=${PKG//\"/}

  echo "----------------------------------------"
  echo "Installing/upgrading: $PKG"
  echo "----------------------------------------"
  "$PYTHON" -m pip install --user --upgrade --no-compile --no-cache-dir "$PKG" || {
    echo "!! Failed to install $PKG (continuing)"
  }
  echo
done

########################################
# 7. Optional: wrapper for gdown in /storage/bin
########################################

if [ -d /storage/bin ] && [ -x "$BIN_DIR/gdown" ]; then
  WRAP=/storage/bin/gdown
  if [ ! -x "$WRAP" ]; then
    echo "==> Creating gdown wrapper at $WRAP"
    cat >"$WRAP" <<EOF
#!/bin/sh
exec "$BIN_DIR/gdown" "\$@"
EOF
    chmod +x "$WRAP"
  fi
fi

########################################
# 8. Final summary
########################################

echo "==> Installation complete."
echo
echo "Installed tools (requested):"
for PKG in $CHOICE_TEXT; do
  PKG=${PKG//\"/}
  echo "  - $PKG"
done

echo
echo "Make sure a new shell inherits PATH with:"
echo "  $BIN_DIR"
echo "already appended (this script updated ~/.profile and ~/.bashrc)."
echo
echo "Example usage:"
echo "  gdown \"https://drive.google.com/file/d/FILE_ID/view?usp=sharing\""
echo "  yt-dlp URL"
echo "  glances"
echo "  speedtest-cli"
echo "  python3 -m pygame.examples.aliens   # test pygame"
echo
