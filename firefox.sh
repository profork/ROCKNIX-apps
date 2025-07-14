#!/bin/bash
# Rocknix Firefox 139.0.4 Installer with automatic YouTube Leanback launcher

APP_DIR="/storage/Applications/firefox"
PORTS_DIR="/storage/roms/ports"
PROFILE_DIR="/storage/.firefox"
FIREFOX_URL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/139.0.4/linux-aarch64/en-US/firefox-139.0.4.tar.xz"
ARCHIVE_NAME="firefox-139.0.4.tar.xz"
GPTK_FILE="$PORTS_DIR/firefox.gptk"
FIREFOX_LAUNCHER="$PORTS_DIR/Firefox.sh"
YOUTUBE_LAUNCHER="$PORTS_DIR/YoutubeTV.sh"
UA_PREF="$PROFILE_DIR/user.js"

echo "📦 Installing Firefox 139.0.4 (Rocknix, aarch64 only)..."
sleep 2

# Step 1: Download and extract Firefox
echo "🔽 Downloading Firefox tarball..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"
rm -f "$ARCHIVE_NAME"

if ! wget -O "$ARCHIVE_NAME" "$FIREFOX_URL"; then
    curl -Lo "$ARCHIVE_NAME" "$FIREFOX_URL"
fi

echo "📂 Extracting Firefox..."
tar -xf "$ARCHIVE_NAME" --strip-components=1
chmod +x firefox
rm -f "$ARCHIVE_NAME"

# Step 2: Create profile and GPTK mapping
mkdir -p "$PROFILE_DIR"
mkdir -p "$PORTS_DIR"

echo "🎮 Writing GPTK mapping..."
cat > "$GPTK_FILE" <<EOF
up = up
down = down
left = left
right = right
a = enter
b = esc
x = ctrl+w
y = ctrl+t
start = enter
select = esc
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# Step 3: Create default Firefox launcher
echo "🚀 Creating Firefox launcher..."
cat > "$FIREFOX_LAUNCHER" <<EOF
#!/bin/bash
trap 'pkill gptokeyb' EXIT

export DISPLAY=:0.0
export HOME="$PROFILE_DIR"

gptokeyb -p "firefox" -c "$GPTK_FILE" -k firefox &
sleep 1
"$APP_DIR/firefox" -profile "$PROFILE_DIR"
EOF

chmod +x "$FIREFOX_LAUNCHER"

# Step 4: Create YouTube TV launcher
echo "🖥️  Creating YouTube Leanback launcher..."
echo 'user_pref("general.useragent.override", "Roku/DVP-9.10 (519.10E04111A)");' >> "$UA_PREF"

cat > "$YOUTUBE_LAUNCHER" <<EOF
#!/bin/bash
trap 'pkill gptokeyb' EXIT

export DISPLAY=:0.0
export HOME="$PROFILE_DIR"

gptokeyb -p "firefox" -c "$GPTK_FILE" -k firefox &
sleep 1
"$APP_DIR/firefox" -kiosk -profile "$PROFILE_DIR" "https://www.youtube.com/tv"
EOF

chmod +x "$YOUTUBE_LAUNCHER"

echo "✅ Firefox 139.0.4 installed!"
echo "▶️ Launch Firefox from: $FIREFOX_LAUNCHER"
echo "📺 Launch YouTube TV UI from: $YOUTUBE_LAUNCHER"
echo "🎮 Exit with Start+Select"
echo "Rockchip SOC users may need to switch to Panfrost video Driver"
