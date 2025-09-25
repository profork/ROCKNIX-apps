#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
URL="https://github.com/profork/ROCKNIX-apps/raw/main/pygame/oui.7z"

# Prefer persistent tmp on Rocknix if writable
if [ -w /storage/tmp ] 2>/dev/null; then
  TMP="$(mktemp -d /storage/tmp/oui.XXXXXX)"
else
  TMP="$(mktemp -d)"
fi

ARCHIVE="$TMP/oui.7z"
OUTDIR="$TMP/extracted"
EXPECT_SCRIPT="$TMP/unwrap.exp"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# --- Ensure pkgx is present ---
if ! command -v pkgx >/dev/null 2>&1; then
  echo "❌ pkgx not found. Please install pkgx first." >&2
  exit 1
fi

SEVENZ="pkgx 7z"

# --- Download ---
echo "📥 Downloading encrypted archive…"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "$ARCHIVE" "$URL"
else
  wget -q -O "$ARCHIVE" "$URL"
fi
[ -s "$ARCHIVE" ] || { echo "❌ Download failed or empty file." >&2; exit 1; }

# --- Read passphrase securely ---
read -r -s -p "Passphrase: " PW
echo
[ -n "$PW" ] || { echo "❌ No passphrase entered."; exit 2; }

mkdir -p "$OUTDIR"

# --- Extract (prefer expect if present) ---
if command -v expect >/dev/null 2>&1; then
  cat >"$EXPECT_SCRIPT" <<'EOF'
#!/usr/bin/expect -f
set timeout -1
set bin [lindex $argv 0]
set archive [lindex $argv 1]
set outdir [lindex $argv 2]
set passwd [lindex $argv 3]

spawn {*}$bin x -y -o$outdir $archive
expect {
  -re "(Enter password.*:|Enter password.*)" {
    send -- "$passwd\r"
    exp_continue
  }
  eof
}
EOF
  chmod +x "$EXPECT_SCRIPT"
  "$EXPECT_SCRIPT" "$SEVENZ" "$ARCHIVE" "$OUTDIR" "$PW"
else
  echo "⚠️  'expect' not found; using fallback (password may appear briefly in process args)."
  $SEVENZ x -y -o"$OUTDIR" -p"$PW" "$ARCHIVE"
fi

# --- Locate and run oui.sh ---
OUI_SH="$(find "$OUTDIR" -type f -name 'oui.sh' -print -quit || true)"
if [ -z "$OUI_SH" ]; then
  echo "❌ Installer (oui.sh) not found inside archive." >&2
  exit 3
fi

chmod +x "$OUI_SH"
echo "▶ Running $(basename "$OUI_SH")…"
bash "$OUI_SH"
