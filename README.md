# 🐧 ROCKNIX third-party Apps and tools

Quick-install scripts for popular desktop apps and services on Rocknix.  
Some launchers use Alpine chroot environments and are gamepad-friendly where applicable.

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

*(Compatibility varies -- 8550/ODIN 2 worked.  RK3566 and RK3588  didn't work -- 6-8 gb RAM seems to be minimum

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/chromium/chromium.sh | bash
```

---

## 📺 Kodi (Alpine Chroot)

Kodi media center running in an Alpine chroot.  
Includes ALSA support and optional gamepad hotkeys.

*(Performance varies; needs higher end devices for smoother video playback)

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/kodi/kodi.sh | bash
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
