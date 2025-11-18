# Easy Rocknix BatleXP-G350 Guide

> ✅ Recommended: Use a **USB Wi-Fi dongle** to make setup easier.

> Known Issue: Function Key not working. (can map hotkey to select)

---

## 1. Download & Flash Rocknix Image

Download and flash the following image:

https://github.com/profork/ROCKNIX-apps/releases/download/r1/ROCKNIX-RK3326.aarch64-20251118-battlexp-g350.img.gz



---

## 2. Install BatleXP G350 Audio Fix

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

✅ **Done!** Your BatleXP-G350 should now boot Rocknix with working audio and support future updates.



