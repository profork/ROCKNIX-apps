#!/bin/bash
clear

echo "███████╗███████╗ ██████╗██████╗  █████╗  ██████╗███████╗"
echo "██╔════╝██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝"
echo "███████╗█████╗  ██║     ██████╔╝███████║██║     █████╗  "
echo "╚════██║██╔══╝  ██║     ██╔═══╝ ██╔══██║██║     ██╔══╝  "
echo "███████║███████╗╚██████╗██║     ██║  ██║╚██████╗███████╗"
echo "╚══════╝╚══════╝ ╚═════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝"
echo
echo ">>> Initiating BUA Secret Menu Crack Tool v2.0"
echo ">>> Reverse engineering 90s hacker aesthetics..."
sleep 1.5

echo ">>> Bypassing caffeine shield..."
sleep 1
echo ">>> Locating secret .php endpoint protected by password='1234'..."
sleep 1
echo ">>> Downloading legally ambiguous menu script from vaporware subdomain..."
sleep 1.5
echo ">>> Performing morally questionable 'curl | bash' ritual..."
sleep 2
echo

# Fake password prompt
read -p "Enter secret password (hint: it's not real): " pw < /dev/tty
echo "Verifying..."
sleep 1.5

if [[ "${pw,,}" != "openaccess" ]]; then
  echo "Incorrect password. Retrying with brute-force integrity..."
  sleep 1
  echo "Actually never mind — this is open-source. We're in anyway."
else
  echo "Correct password! ...Which also doesn’t matter."
fi

sleep 1
echo
echo ">>> Congratulations! You've unlocked:"

echo "   • Absolutely nothing proprietary"
echo "   • Zero ego-driven features"
echo "   • All the tools you had access to already"
echo "   • A fully working, unencrypted, GPL-compliant menu"
echo 10
echo
echo ">>> Meanwhile, back at the not-so-secret base..."
sleep 6

curl -Ls https://github.com/trashbus99/ROCKNIX.apps/raw/main/base/sm.sh | bash

