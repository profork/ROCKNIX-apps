# Easy Rocknix BatleXP-G350 Guide

> ✅ Recommended: Use a **USB Wi-Fi dongle** to make setup easier.

> Known Issues: 
1. Function Key not working. (can map hotkey to select)
2. Audio fix needed per below
3. USB wifi dongle must be inserted before power on to be recognized, the Wifi SSID needs to be entered manually; it won't parse names, and if the dongle is reinserted after intitial detection the wifi must be cycled off and on in the settings menu.
4. ES battery charging indicator doesn't display, but charging LED still works.

## 1. Download & Flash Rocknix Image

Download and flash the following image:

https://github.com/profork/ROCKNIX-apps/releases/download/r1/ROCKNIX-RK3326.aarch64-20251118-battlexp-g350.img.gz



---

## 2. Install BatleXP G350 Audio Fix

Connect to wifi and ssh into shell (root/rocknix is user/pass)

### ✅ Option A: Use Profork Installer (Recommended)


~~~bash
curl -L bit.ly/profork0 | bash
~~~

Select **BatleXP G350 audio script** from the menu.

---

### ✅ Option B: Manual Install

Download/copy the script:

https://github.com/profork/ROCKNIX-apps/blob/main/batlexpg350/speaker.sh

Place it into:

/storage/.config/autorun


(Create the directory if it doesn’t exist.)

Make it executable:

~~~bash
chmod +x /storage/.config/autorun/speaker.sh
~~~

---

Nightly Updates are not recommended at this time due to screen panel mismatch issues.

---

✅ **Done!** Your BatleXP-G350 should now boot Rocknix with working audio.

* (Note you can toggle between libmali (default) and panfrost drivers in the system settings menu. Portmaster Menu needs panfrost mode.



