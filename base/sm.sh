#!/bin/bash

# File paths
JEOPARDY_AUDIO="/userdata/music/jeopardy.mp3"
RICKROLL_AUDIO="/userdata/music/rickroll.mp3"
LOSER_HORN_AUDIO="/userdata/music/loserhorn.mp3"

# Your hosted GitHub MP3 URLs
JEOPARDY_URL="https://github.com/trashbus99/profork/raw/master/.dep/.ytrk/at.mp3"
RICKROLL_URL="https://github.com/trashbus99/profork/raw/master/.dep/.ytrk/ee.mp3"
LOSER_HORN_URL="https://github.com/trashbus99/profork/raw/master/.dep/.ytrk/lh.mp3"

# Ensure the directory exists
mkdir -p /userdata/music

# Download MP3s if missing
for file in "$JEOPARDY_AUDIO" "$RICKROLL_AUDIO" "$LOSER_HORN_AUDIO"; do
    case $file in
        "$JEOPARDY_AUDIO") URL="$JEOPARDY_URL" ;;
        "$RICKROLL_AUDIO") URL="$RICKROLL_URL" ;;
        "$LOSER_HORN_AUDIO") URL="$LOSER_HORN_URL" ;;
    esac

    if [ ! -f "$file" ]; then
        wget -q -O "$file" "$URL"
    fi
done

# Play Jeopardy theme quietly in background
if command -v cvlc >/dev/null 2>&1; then
    cvlc --play-and-exit --no-video "$JEOPARDY_AUDIO" >/dev/null 2>&1 &
elif command -v mpg123 >/dev/null 2>&1; then
    mpg123 -q "$JEOPARDY_AUDIO" &
fi
MUSIC_PID=$!

# Prompt for password
PASSWORD=$(dialog --nocancel --inputbox "Enter the secret password:\n\nHint: In 2101, war was beginning...\nClassic Engrish from Zero Wing." 12 60 3>&1 1>&2 2>&3)

# Stop Jeopardy music
kill "$MUSIC_PID" 2>/dev/null

# Normalize input
PASSWORD_NORM=$(echo "$PASSWORD" | tr '[:upper:]' '[:lower:]')
SECRET="all your base are belong to us"

# Check password
if [ "$PASSWORD_NORM" == "$SECRET" ]; then
    dialog --msgbox "ACCESS GRANTED." 6 40
    sleep 1

    # Play Rickroll in background
    if command -v cvlc >/dev/null 2>&1; then
        cvlc --play-and-exit --no-video "$RICKROLL_AUDIO" >/dev/null 2>&1 &
    elif command -v mpg123 >/dev/null 2>&1; then
        mpg123 -q "$RICKROLL_AUDIO" &
    fi
    RICK_PID=$!

    # Troll message
    dialog --msgbox "
Well done, retro warrior.

You cracked the code. You spoke the ancient phrase. You are now among the elite who understand that 'somebody set up us the bomb.'

Decrypting will begin shortly...
" 20 60

    # Kill Rickroll
    kill "$RICK_PID" 2>/dev/null

    # Fake terminal animation mocking BUA "secret menu"
clear
echo ">>> INITIATING BREACH: BUA SECRET MENU PROTOCOL <<<"
sleep 3
echo "Establishing handshake with BUA core node..."
sleep 3
echo "Requesting secret access token: [DENIED]"
sleep 3
echo "Bypassing Discord Gatekeeping Layer..."
sleep 3
echo "Injecting zero-day exploit: /tmp/zig_executor.sh"
sleep 3
echo "✓ Gatekeeper distracted by animated GIFs."
sleep 3
echo "Brute-forcing secret menu password via dictionary attack..."
sleep 3
echo "✓ Match found: 'all your base are belong to us'"
sleep 3
echo "Decrypting with ROT13 + Base64 + NostalgiaCodec™"
sleep 3
echo "Launching proprietary de-scrambler: BUA_UNSCRAMBLE_V69.EXE"
sleep 3
echo "Downloading assets from secret_mirror.bua.lan... [403 Forbidden]"
sleep 3
echo "Spoofing MAC address: DE:AD:BE:EF:42:00"
sleep 3
echo "Establishing backdoor via kevo.bato.api... connected."
sleep 3
echo "Extracting package: /userdata/roms/bua/secret_menu.7z"
sleep 3
echo "Mounting drive: /dev/kevobatogatekeeper"
sleep 3
echo "Scanning for mystical submenus... 404: Not Found"
sleep 3
echo ""
echo ">>> DECRYPT SUCCESSFUL: DISPLAYING CONTENTS <<<"
sleep 3
echo "- README.md (empty file)"
echo "- rm -f /addons/myirentfetcher.sh "
echo "- /themes/classic_blue_with_glitch_01/"
echo "- note.txt: 'lol don't tell anyone this doesn't do anything'"
sleep 5
echo ""
echo "📡 Sending discovery log to: kevo.bato.visibility.api"
sleep 3
echo "📺 YouTube index response: 'Not eligible for coverage.'"
sleep 3
sleep 3
echo "🤖 KevoBot says: 'If it's not BUA, it's not real. Stay safe.'"
sleep 3
echo  "recovering non-BUA alternative censorsed comments"
sleep 2
echo ""
echo "📎 Suggestion: Relax, Kevo. It’s just bash and memes."
sleep 3
echo "💊 Consider: One chill pill with water. Maybe two if sarcasm allergy persists."
sleep 3
echo ""
echo "Finalizing exit sequence..."
sleep 4
echo "Mission complete. You successfully hacked into... nothing."
sleep 4
echo "Returning to real tools that actually do things."
sleep 3
clear
echo ""
echo ">>> SCANNING FOR OFFICIAL BATOCERA SUPPORT <<<"
sleep 4
echo "🛰️  Pinging Batocera Dev HQ..."
sleep 3
echo "Response: 'Addons are unsupported. Use at your own risk.'"
sleep 3
echo "🔒 EchoChamberShield™ active: filtering user ideas..."
sleep 4
echo "📤 Forwarding suggestions to /dev/null..."
sleep 3
echo "🧠 Dev response auto-generated: 'You shouldn't need that feature anyway.'"
sleep 4
echo "🧼 Sanitizing forums of non-approved creativity...Disregarding UUREEL's suggestions"
sleep 4
echo "🚷 Warning: This script violates the Prime Directive — *having fun independently*."
sleep 4
echo "🗂️  Filing report: Unauthorized script detected. Possible threat to groupthink."
sleep 2
echo ""
echo "📎 Suggestion: If it works and it's helpful, it's probably 'not official'."
sleep 4
echo ""
echo "⚠️  The following sequence is a satirical diagnostic report."
echo "Any resemblance to real devs is purely coincidental... unless it isn’t."
sleep 4
echo ""
clear
echo ">>> FINAL REPORT: INTERNAL BATOCERA DEV MATRIX <<<"
sleep 5
echo "Analyzing communication protocols..."
sleep 5
echo "Filtering constructive feedback... [DISCARDED]"
sleep 5
echo ""
echo "🧠 'EntropyMost': Detected extreme allergy to third-party scripts."
echo "  Status: Perma-triggered by anything not written inside his echo chamber."
echo "  Recommendation: Prescribe bash-blocker and a sense of humor."
sleep 5
echo ""
echo "👑 'French_Batocera_King_guy': Logged as project lead archetype."
echo "  Notes: Downplayed innovative ideas, rerouted creativity to /dev/oblivion."
echo "  Activity: Still coding more wheels."
sleep 5
echo ""
echo "🐍 'Down-Under-Type': Gruff INTJ variant detected. Fe-Trickster online."
echo "  Description: Brutal honesty delivered via sandpaper. Fluent in Australian sarcasm."
echo "  Dialogue samples:"
echo "    • 'Stick to the Topic.'"
echo "    • 'You clearly don’t understand the structure.'"
echo "    • 'No.'"
sleep 7
echo ""
echo "📉 System behavior:"
echo "  - Community suggestions: Ignored"
echo "  - Addons: Flagged as threats"
echo "  - Working forks: Treated like betrayals"
sleep 5
echo ""
echo "📎 Psychological assessment:"
echo "  - Leadership style: Consensus illusion"
echo "  - Bug triage method: GitHub hide-and-seek"
echo "  - Morale management: Forum censorship + Discord Ghosting"
sleep 5
echo ""
echo "One Useful advice discovered:"
echo "Mikhailzrick: Get an N100!"
sleep 5     
echo  "Another constructive piece of advice discovered: UUREEL: Use Retrobat."
sleep 5
echo  ""
echo "💥 Final Statement: If it wasn't born inside the echo chamber, it doesn't exist."
sleep 3
echo "📬 All creative thoughts have been safely redirected to /dev/null"
sleep 4


    echo ">>> Meanwhile, back at the not-so-secret base..."
sleep 3

# Optional jab
echo "NOTE: Unlike other menus, this one doesn't redirect through an encrypted .php script hosted behind rainbow unicorns."

sleep 2
echo
echo "Launching Profork main menu..."
sleep 2

# Relaunch main menu
curl -Ls https://github.com/trashbus99/profork/raw/master/app/mainmenu.sh | bash
   
else
    # Wrong password → Play the Price is Right Loser Horn
    if command -v cvlc >/dev/null 2>&1; then
        cvlc --play-and-exit --no-video "$LOSER_HORN_AUDIO" >/dev/null 2>&1 &
    elif command -v mpg123 >/dev/null 2>&1; then
        mpg123 -q "$LOSER_HORN_AUDIO" &
    fi
    HORN_PID=$!

    dialog --msgbox "ACCESS DENIED.

You have failed the sacred test of retro meme literacy.

Your failure is now being recorded for future Batocera historians.

Please reflect on your choices." 15 60

    kill "$HORN_PID" 2>/dev/null
    sleep 2  # Extra time before script exits
clear
    echo ""
    echo "================================================="
    echo " ACCESS DENIED. SHAME DEPLOYED."
    echo " Tip: The password was not 'OpenSesame123'."
    echo " You may now return to Discord to argue about it."
    echo " THIS IS NOW RETURNING TO THE MAIN MENU."
    echo "================================================="
    sleep 7
    echo ">>> Meanwhile, back at the not-so-secret base..."
sleep 3

# Optional jab
echo "NOTE: Unlike other menus, this one doesn't redirect through an encrypted .php script hosted behind rainbow unicorns."

sleep 2
echo
echo "Launching Profork main menu..."
sleep 2

# Relaunch main menu
curl -Ls https://github.com/trashbus99/profork/raw/master/app/mainmenu.sh | bash
fi

# 🔥 Auto-delete the MP3s so they always get re-downloaded!
rm -f "$JEOPARDY_AUDIO" "$RICKROLL_AUDIO" "$LOSER_HORN_AUDIO"
