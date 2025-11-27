#!/bin/sh
# batocera-rom-pack installer for Rocknix

set -e

URL="https://github.com/profork/ROCKNIX-apps/releases/download/r1/batocera-rom-pack.zip"
ROMDIR="/storage/roms"
TMPDIR="/storage/tmp"
ZIPFILE="${TMPDIR}/batocera-rom-pack.zip"

echo "==> Preparing directories..."
mkdir -p "$ROMDIR" "$TMPDIR"

echo "==> Downloading batocera-rom-pack.zip..."
# busybox wget supports -O
wget -O "$ZIPFILE" "$URL"

echo "==> Unzipping into ${ROMDIR} (overwriting existing files)..."
# -o = overwrite without prompting
unzip -o "$ZIPFILE" -d "$ROMDIR"

echo "==> Cleaning up..."
rm -f "$ZIPFILE"

echo "==> Done. Freeware ROM folders installed under ${ROMDIR}."
