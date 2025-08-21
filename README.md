# 🐧 ROCKNIX third-party Apps and tools

Quick-install scripts for popular desktop apps and services on Rocknix.  
Some launchers use Alpine chroot environments and are gamepad-friendly where applicable.
---
## Desktop Mode

Runnimage Arch Container running XFCE Desktop

<img width="1916" height="1048" alt="image" src="https://github.com/user-attachments/assets/3274127d-842f-4025-8d38-2cf230c6e4af" />

```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/desktop/runimage-desktop.sh | bash
```
*First Launch can take a while as it downloads Desktop packages from Arch Repositories in background.

---

## 🦊 Firefox  

*(Compatibility varies -- SM8550/ODIN 2 and RK3588 Worked , RK3566 didn't work -- 4gb RAM seems to be minimum)

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/firefox.sh  | bash
```

---

## 🦊 LibreWolf + YouTube Leanback (TV UI)

Launches LibreWolf with a custom profile tailored for YouTube Leanback (TV UI).  
Includes GPTK mappings for full gamepad navigation in Youtube Leanback.

*(Recommended for Lower end devices)

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/librewolf/librewolf.sh | bash
```

---

## 🌐 Chromium (Alpine Chroot)

Chromium web browser with web app shortcuts to:
- GeForce Now  
- Amazon Luna  
- Xbox Cloud Gaming (Xcloud)

(You will need a mouse/kb to log in)

*(Compatibility varies -- SM8550/ODIN 2 worked.  RK3566 and RK3588 (4GB)  didn't work -- 6-8 gb RAM seems to be minimum

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/chromium/chromium.sh | bash
```

---

## 📺 Kodi (Runimage Arch Container)

*Kodi media Center in an Arch Container.

*Includes ALSA support and optional gamepad hotkeys.



**Arch Container Version Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/kodi/kodi-installer.sh | bash 
```
---
---
## ES CARBON THEME (BATOCERA)
<img width="1279" height="801" alt="image" src="https://github.com/user-attachments/assets/bd3a315a-051a-4ae7-bb22-a256b4932473" />


```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/es-carbon.sh | bash
```
---
## 🧰 PKGX (CLI Tool Manager)

Lightweight CLI package manager from [pkgx.dev](https://pkgx.dev/pkgs/).

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/pkgx/pkgx.sh | bash
```



---

## 🚀 Soar (Pkg-Forge pkg manager)

More static linked  CLI tools and apps maintained by PKG-Forge https://github.com/pkgforge/soar
**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/soar.sh | bash
```

Useful lists:
For Apps/Packages `soar list 'pkgcache' | more`
For Bin (CLI tools) `soar list 'bincache' | more`
