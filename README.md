# 🐧 ROCKNIX Third-Party Apps & Tools

Quick-install scripts for popular desktop apps and services on Rocknix.  
Some launchers use Arch Runimage or Alpine chroot environments and are gamepad-friendly where applicable.

---

## 🖥️ Desktop Mode

**Runimage Arch Container with XFCE Desktop**

![Desktop preview](https://github.com/user-attachments/assets/3274127d-842f-4025-8d38-2cf230c6e4af)

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/desktop/runimage-desktop.sh | bash
```

*First launch may take a while as it downloads Arch desktop packages in the background. Mouse/Kb recommended*

---
## Steam in Runimage (experimental)

**Steam running in arch runimage container**
 Install:
 ```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/steam.sh | bash
```

*Mouse/keyboard recommended. Starts in desktop mode. Experimental. High end device/6gb+ recommended. Steam input doesn't appear to work on built in controllers, but appears to work on external controllers. Relies on the games native controller support for internal controller fallback. Takes a while to Start up*

---

## 📂 Caja + Engrampa (File Manager & Archiver)

Caja GUI file manager with Engrampa archiver (zip, rar, 7zip, etc.) via Runimage.  

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/caja/caja-install.sh | bash
```

*Mouse/keyboard recommended. Rockchip users: enable Panfrost drivers.*

---

 ## 🎬 Vacuumtube - Youtube Leanback TV (more features than Librewolf version)

```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/vacuumtube.sh | bash
```
Rockchip SOC users switch to panfrost drivers

---


 ## 🎮 Greenlight (XBOX remote streaming and Xcloud Client)

```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/greenlight.sh | bash
```
* Needs Mouse/Kb and or touchpad with onscreen kb to login / exit
* Rockchip SOC devices use panfrost.

---
## 🎮 Chaiki (PS4/5 Streamer)



Install:
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/chiaki/chiaki.sh | bash
```
*Only seems to work on adreno devices SM8250/SM8550

*Touch/kb or mouse/kb needed

---

## 🌐 Firefox Browser

*(Compatibility varies — works on SM8550/ODIN 2 and RK3588; does not work on RK3566. 4GB RAM minimum.)*

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/firefox.sh | bash
```

---

## 🌐 Brave Browser (AppImage)

* Tested on Powkiddy X55 (2GB) and Orange Pi 5 (4GB) in Panfrost mode.  
* Rockchip SoCs require Panfrost.  
* Includes launchers for GeForce NOW, Xbox Cloud, and Amazon Luna.
 * Mouse/Keyboard needed

   
Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/brave/brave.sh | bash
```
---

## 🌐Ungoogled-Chromium (AppImage)

* Rockchip SoCs require Panfrost.   
* Mouse/Keyboard or Touch keyboard needed

   
Install:
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/ugc.sh | bash
```
---

## 📺 LibreWolf + YouTube Leanback (TV UI)

Launches LibreWolf plus a separate custom launcher profile tailored for YouTube Leanback.  
Includes GPTK mappings for full gamepad navigation.  
*(Recommended for lower-end devices.)*

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/librewolf/librewolf.sh | bash
```

---

## 🌐 Chromium (Alpine Chroot)

Chromium browser with shortcuts for:
- GeForce NOW  
- Amazon Luna  
- Xbox Cloud Gaming  

*(Mouse/keyboard required to log in. Works on SM8550/ODIN 2. Didn't work on RK3566 and RK3588--appears to need 6–8GB RAM.)*

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/chromium/chromium.sh | bash
```

---

## 🎬 Kodi Media Center (Arch Container)

* Kodi in an Arch container.  
* Includes ALSA support and optional gamepad hotkeys.

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/kodi/kodi-installer.sh | bash
```

---

## 🎨 ES Carbon Theme (Batocera)

![ES Carbon theme](https://github.com/user-attachments/assets/bd3a315a-051a-4ae7-bb22-a256b4932473)

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/es-carbon.sh | bash
```

---

## 🎵 ES Music Pack  

Music from Batocera, Knulli, and Reg-Linux.

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/music.sh | bash
```

---

## 🎮 Free Homebrew ROM Pack  

ROMs bundled with Emudeck Store, Batocera, & Reg-Linux.

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/freebatroms.sh | bash
```

---

## 📦 Flatpak via Runimage

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/flatpak/flatpak.sh | bash
```
Chromium/Electron based apps refuse to run from wrapper.

---

## 🚀 Soar (Pkg-Forge Package Manager)

Static-linked CLI tools and apps from [pkgforge/soar](https://github.com/pkgforge/soar).  

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/soar.sh | bash
```

Useful commands:
```bash
soar list 'pkgcache' | more   # Apps/Packages
soar list 'bincache' | more   # CLI Tools
```

---

## 🧰 PKGX (CLI Tool Manager)

Lightweight CLI package manager from [pkgx.dev](https://pkgx.dev/pkgs/).  

Install:
```bash
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/pkgx/pkgx.sh | bash
```
