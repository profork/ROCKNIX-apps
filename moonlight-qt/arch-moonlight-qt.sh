#!/bin/bash
# RunImage-based Moonlight Qt installer for Rocknix

set -euo pipefail

# === Directories and constants ===
RI_WORKDIR="/storage/ri"
RI_IMAGE="$RI_WORKDIR/runimage"
RI_BUILT="$RI_WORKDIR/moonlight-runimage"
PORTS_DIR="/storage/roms/ports"
RI_DIR="$PORTS_DIR/runimage"
LAUNCHER="$PORTS_DIR/runimage-moonlight.sh"

echo "➤ Creating working dirs..."
mkdir -p "$RI_WORKDIR" "$RI_DIR" "$PORTS_DIR"

# === Step 1: Fetch RunImage ===
if [ ! -f "$RI_IMAGE" ]; then
  echo "➤ Downloading runimage-aarch64..."
  curl -L -o "$RI_IMAGE" https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-aarch64
  chmod +x "$RI_IMAGE"
else
  echo "✔ RunImage already exists."
fi

# === Step 2: Install Moonlight inside overlay ===
echo "➤ Installing moonlight-qt in container..."
RIM_ALLOW_ROOT=1 RIM_OVERFS_ID=moonlight RIM_KEEP_OVERFS=1 "$RI_IMAGE" \
  rim-shell -c "pacman -Sy --noconfirm && pacman -S --noconfirm moonlight-qt"

# === Step 3: Rebuild image ===
echo "➤ Rebuilding Moonlight RunImage..."
RIM_ALLOW_ROOT=1 RIM_OVERFS_ID=moonlight "$RI_IMAGE" rim-build "$RI_BUILT"

# === Step 4: Move built image to ports dir ===
mv -f "$RI_BUILT" "$RI_DIR/moonlight-runimage"
chmod +x "$RI_DIR/moonlight-runimage"

# === Step 5: Create launcher ===
cat > "$LAUNCHER" <<EOF
#!/bin/bash
# Launch Moonlight Qt via RunImage

set -euxo pipefail
cd "$RI_DIR"

# Launch Moonlight with Pulse + storage passthrough
exec env \\
  RIM_ALLOW_ROOT=1 \\
  RIM_PORTABLE_HOME=1 \\
  RIM_PORTABLE_CONFIG=1 \\
  RIM_BIND=/run/user/0/pulse/native:/run/user/0/pulse/native,/storage:/media/storage \\
  ./moonlight-runimage moonlight-qt
EOF

chmod +x "$LAUNCHER"

# === Done ===
echo " - RunImage: $RI_DIR/moonlight-runimage"
echo " - Launcher: $LAUNCHER"
echo " - No GPTK needed (native controller support)"
echo " - Removing build folder"
rm -rf ~/ri
echo "✅ Moonlight RunImage installed!"

