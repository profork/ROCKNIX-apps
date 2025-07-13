#!/bin/bash
# setup_youtube_tv_and_librewolf.sh
#
# This script:
#   - Downloads the LibreWolf AppImage to /storage/Applications.
#   - Configures LibreWolf for YouTube TV using a dedicated profile (/storage/.librewolf)
#     with a forced user agent of "Roku/DVP-9.10 (519.10E04111A)".
#   - Creates two GPTK mapping files (following the gptokeyb GitHub syntax) in /storage/roms/ports:
#       1. youtube_tv.gptk: Includes basic navigation keys, face buttons, left analog stick mapping,
#          and a hotkey (L1+start+select) mapped to Alt+F4.
#       2. librewolf.gptk: Includes basic navigation keys, face buttons, left analog stick mapping,
#          and a hotkey (start+select) mapped to Alt+F4.
#   - Generates two launch scripts in /storage/roms/ports:
#         1. YoutubeTV.sh: Launches gptokeyb for controller mapping and then LibreWolf in kiosk mode.
#         2. Librewolf.sh: Launches gptokeyb for controller mapping and then LibreWolf in normal windowed mode.
#
# Requirements: wget or curl, LibreWolf AppImage, gptokeyb.

# Display installation message with a delay.
echo "This will install the LibreWolf web browser and YouTube TV UI mode launch scripts to ports."
echo "Installation will begin in 5 seconds..."
sleep 5

# ---------------------------
# Step 1: Download and Set Up LibreWolf
# ---------------------------
LIBREWOLF_URL="https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/135.0-1/LibreWolf.aarch64.AppImage"

echo "Downloading LibreWolf AppImage..."
mkdir -p /storage/Applications
cd /storage/Applications
# Remove any existing file to avoid 'Text file busy' errors.
rm -f LibreWolf.AppImage
if ! wget -O LibreWolf.AppImage "$LIBREWOLF_URL"; then
    curl -Lo LibreWolf.AppImage "$LIBREWOLF_URL"
fi

echo "Setting executable permissions on LibreWolf.AppImage..."
chmod +x LibreWolf.AppImage

echo "Configuring LibreWolf settings for YouTube TV..."
# Define the user agent and other necessary settings.
PROFILE_DIR="/storage/.librewolf"
mkdir -p "$PROFILE_DIR"
cat > "$PROFILE_DIR/user.js" <<EOF
// Ensure YouTube TV UI loads with the proper user agent.
user_pref("general.useragent.override", "Roku/DVP-9.10 (519.10E04111A)");

// Enable gamepad support.
user_pref("dom.gamepad.enabled", true);
user_pref("dom.gamepad.extensions.enabled", true);

// Basic settings to persist logins and session data.
user_pref("privacy.resistFingerprinting", false);
user_pref("network.cookie.cookieBehavior", 1);
user_pref("signon.autofillForms", true);
user_pref("signon.rememberSignons", true);

// Prevent clearing cookies & storage on shutdown.
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.sanitize.pending", "");
user_pref("privacy.clearOnShutdown.cache", false);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.offlineApps", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("privacy.clearOnShutdown.siteSettings", false);

// Ensure sessions and cookies persist.
user_pref("browser.privatebrowsing.autostart", false);
user_pref("browser.sessionstore.privacy_level", 0);
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("network.cookie.lifetimePolicy", 0);
user_pref("network.cookie.cookieBehavior", 1);
EOF

# (Optional) Remove prefs.js so that LibreWolf regenerates it from user.js.
rm -f "$PROFILE_DIR/prefs.js"

# ---------------------------
# Step 2: Create the GPTK Mapping Files
# ---------------------------
PORTS_DIR="/storage/roms/ports"
mkdir -p "$PORTS_DIR"

# (A) GPTK mapping file for YouTube TV.
echo "Creating GPTK mapping file for YouTube TV..."
GPTK_YOUTUBE_FILE="$PORTS_DIR/youtube_tv.gptk"
cat > "$GPTK_YOUTUBE_FILE" <<EOF
up = up
down = down
left = left
right = right
a = enter  
b = esc
x = space
y = space
start = enter
select = esc
# Map left analog stick directions to the same keys as the D-pad
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right
hotkey = L1+start+select:KEY_LEFTALT+KEY_F4
EOF

# (B) GPTK mapping file for general LibreWolf.
echo "Creating GPTK mapping file for general LibreWolf..."
LIBREWOLF_GPTK_FILE="$PORTS_DIR/librewolf.gptk"
cat > "$LIBREWOLF_GPTK_FILE" <<EOF
up = up
down = down
left = left
right = right
a = enter  
b = esc
x = space
y = space
start = enter
select = esc
# Map left analog stick directions to the same keys as the D-pad
left_analog_up = up
left_analog_down = down
left_analog_left = left
left_analog_right = right
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# ---------------------------
# Step 3: Create the Launch Scripts
# ---------------------------
# Define the path to gptokeyb.
GPTOKEYB="/usr/bin/gptokeyb"

# (A) Youtube TV Launcher (with gptokeyb mapping and kiosk mode using the dedicated profile)
echo "Creating Youtube TV launch script..."
YOUTUBE_LAUNCHER="$PORTS_DIR/YoutubeTV.sh"
cat > "$YOUTUBE_LAUNCHER" <<EOF
#!/bin/bash
trap 'pkill gptokeyb' EXIT

# Launch gptokeyb using partial matching (-p) on the process name.
\gptokeyb -p "LibreWolf" -c "$GPTK_YOUTUBE_FILE" -k librewolf &
# Allow a short delay for the mappings to load.
sleep 1
# Launch LibreWolf in kiosk mode for YouTube TV using the dedicated profile.
 /storage/Applications/LibreWolf.AppImage --kiosk -profile "$PROFILE_DIR" "https://www.youtube.com/tv"
EOF
chmod +x "$YOUTUBE_LAUNCHER"

# (B) General LibreWolf Launcher (normal windowed mode)
echo "Creating LibreWolf launch script..."
LIBREWOLF_LAUNCHER="$PORTS_DIR/Librewolf.sh"
cat > "$LIBREWOLF_LAUNCHER" <<EOF
#!/bin/bash
trap 'pkill gptokeyb' EXIT

# Launch gptokeyb with the LibreWolf mapping for start+select killing action.
\gptokeyb -p "LibreWolf" -c "$LIBREWOLF_GPTK_FILE" -k librewolf &
# Allow a short delay for the mappings to load.
sleep 1
# Launch LibreWolf in normal (windowed) mode using the default profile.
 /storage/Applications/LibreWolf.AppImage -profile "$PROFILE_DIR"
EOF
chmod +x "$LIBREWOLF_LAUNCHER"

echo "✅ Setup complete!"
echo "Launch YouTube TV with: $YOUTUBE_LAUNCHER"
echo "Launch general LibreWolf with: $LIBREWOLF_LAUNCHER"
echo ""
echo "Note: Rockchip SoCs need to switch to Panfrost drivers."
echo ""
echo "To close Youtube, press select+start"
