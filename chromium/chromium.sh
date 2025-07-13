#!/bin/bash                                                                                                                                                                                                      # Define key directories and files                                                                                                                                                                               CHROOT_DIR="/storage/my-alpine-chroot"                                                                                                                                                                           LAUNCH_SCRIPT_DIR="/storage/roms/ports"                                                                                                                                                                          GPTK_FILE="$LAUNCH_SCRIPT_DIR/chromium.gptk"                                                                                                                                                                                                                                                                                                                                                                                      # Ensure Alpine chroot exists; if not, install it.                                                                                                                                                               if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then                                                                                                                                                echo " ^=^=  Alpine chroot not found. Installing..."                                                                                                                                                             curl -Ls https://github.com/trashbus99/ROCKNIX.apps/raw/main/base/alpine.sh | bash                                                                                                                           fi                                                                                                                                                                                                                                                                                                                                                                                                                                # Install Chromium inside the chroot                                                                                                                                                                             echo " ^=^=  Installing Chromium inside chroot..."                                                                                                                                                               chroot "$CHROOT_DIR" /bin/bash -l <<EOF                                                                                                                                                                          apk update                                                                                                                                                                                                       apk add chromium                                                                                                                                                                                                 EOF                                                                                                                                                                                                                                                                                                                                                                                                                               # Create the launch script directory if it doesn't exist.                                                                                                                                                        mkdir -p "$LAUNCH_SCRIPT_DIR"                                                                                                                                                                                                                                                                                                                                                                                                     # Create a GPTK mapping file that maps start+select to send Alt+F4.                                                                                                                                              cat > "$GPTK_FILE" <<EOF                                                                                                                                                                                         hotkey = start+select:KEY_LEFTALT+KEY_F4                                                                                                                                                                         EOF                                                                                                                                                                                                                                                                                                                                                                                                                               # Function to generate a launcher script.                                                                                                                                                                        # Arguments:                                                                                                                                                                                                     #   1) Script filename                                                                                                                                                                                           #   2) URL to open                                                                                                                                                                                               #   3) Mode: "kiosk" for kiosk/fullscreen mode or "window" for regular mode.                                                                                                                                     create_launcher() {                                                                                                                                                                                                  local script_name="$1"                                                                                                                                                                                           local url="$2"                                                                                                                                                                                                   local mode="$3"                                                                                                                                                                                                  local launcher_path="$LAUNCH_SCRIPT_DIR/$script_name"                                                                                                                                                            local launch_command=""                                                                                                                                                                                                                                                                                                                                                                                                           if [ "$mode" = "kiosk" ]; then                                                                                                                                                                                       launch_command="/usr/bin/chromium --no-sandbox --enable-gamepad --kiosk --start-fullscreen \"$url\""                                                                                                         else                                                                                                                                                                                                                 launch_command="/usr/bin/chromium --no-sandbox --enable-gamepad \"$url\""                                                                                                                                    fi                                                                                                                                                                                                                                                                                                                                                                                                                                cat > "$launcher_path" <<EOF                                                                                                                                                                                 #!/bin/bash                                                                                                                                                                                                                                                                     #!/bin/bash
# Define key directories and files
CHROOT_DIR="/storage/my-alpine-chroot"
LAUNCH_SCRIPT_DIR="/storage/roms/ports"
GPTK_FILE="$LAUNCH_SCRIPT_DIR/chromium.gptk"

# Ensure Alpine chroot exists; if not, install it.
if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
    echo "🟡 Alpine chroot not found. Installing..."
    curl -Ls https://github.com/trashbus99/ROCKNIX.apps/raw/main/base/alpine.sh | bash
fi

# Install Chromium inside the chroot
echo "🟡 Installing Chromium inside chroot..."
chroot "$CHROOT_DIR" /bin/bash -l <<EOF
apk update
apk add chromium
EOF

# Create the launch script directory if it doesn't exist.
mkdir -p "$LAUNCH_SCRIPT_DIR"

# Create a GPTK mapping file that maps start+select to send Alt+F4.
cat > "$GPTK_FILE" <<EOF
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# Function to generate a launcher script.
# Arguments:
#   1) Script filename
#   2) URL to open
#   3) Mode: "kiosk" for kiosk/fullscreen mode or "window" for regular mode.
create_launcher() {
    local script_name="$1"
    local url="$2"
    local mode="$3"
    local launcher_path="$LAUNCH_SCRIPT_DIR/$script_name"
    local launch_command=""

    if [ "$mode" = "kiosk" ]; then
        launch_command="/usr/bin/chromium --no-sandbox --enable-gamepad --kiosk --start-fullscreen \"$url\""
    else
        launch_command="/usr/bin/chromium --no-sandbox --enable-gamepad \"$url\""
    fi

    cat > "$launcher_path" <<EOF
#!/bin/bash
# When the script exits, kill any running gptokeyb instance.
trap 'pkill gptokeyb' EXIT

# Define chroot and environment variables.
CHROOT_DIR="$CHROOT_DIR"
WAYLAND_SOCKET="/run/user/1000/wayland-0"
PULSE_DIR="/run/0-runtime-dir/pulse"
PULSE_SOCKET="\$PULSE_DIR/native"

# Ensure required directories exist in the chroot.
mkdir -p "\$CHROOT_DIR/run/user/1000"
mkdir -p "\$CHROOT_DIR\$PULSE_DIR"
chmod 777 "\$CHROOT_DIR\$PULSE_DIR"

# Bind mount the Wayland socket and PulseAudio directory if not already mounted.
if ! mountpoint -q "\$CHROOT_DIR\$WAYLAND_SOCKET"; then
    mount --bind "\$WAYLAND_SOCKET" "\$CHROOT_DIR\$WAYLAND_SOCKET"
fi
if ! mountpoint -q "\$CHROOT_DIR\$PULSE_DIR"; then
    mount --make-private "\$PULSE_DIR"
    mount --bind "\$PULSE_DIR" "\$CHROOT_DIR\$PULSE_DIR"
fi

# Start gptokeyb with the kill hotkey mapping.
gptokeyb -p "chromium" -c "$GPTK_FILE" -k chromium &
sleep 1

# Launch Chromium in the chroot with gamepad support enabled.
exec chroot "\$CHROOT_DIR" env \\
    WAYLAND_DISPLAY=wayland-0 \\
    PULSE_SERVER=unix:\$PULSE_SOCKET \\
    $launch_command
EOF

    chmod +x "$launcher_path"
    echo "✅ Created launcher: $launcher_path"
}

# Create kiosk-mode launchers for specific websites.
create_launcher "chroot-chromium-spotify.sh" "https://open.spotify.com/" "kiosk"
create_launcher "chroot-chromium-geforcenow.sh" "https://play.geforcenow.com/" "kiosk"
create_launcher "chroot-chromium-amazonluna.sh" "https://luna.amazon.com/" "kiosk"
create_launcher "chroot-chromium-xcloud.sh" "https://www.xbox.com/en-us/play" "kiosk"

# Create a general Chromium launcher (non-kiosk, windowed mode) with Google as the home page.
create_launcher "chroot-chromium.sh" "https://google.com" "window"

echo "✅ All launchers created successfully!"
echo "ROCKSHIP SOC devices need panfrost drivers enabled"
echo "Select+Start Kills chromium"
