# 🐧 ROCKNIX third-party Apps and tools

Quick-install scripts for popular desktop apps and services on Rocknix.  
Some launchers use Alpine chroot environments and are gamepad-friendly where applicable.
---
## Desktop Mode

Runimage Arch Container running XFCE Desktop

<img width="1916" height="1048" alt="image" src="https://github.com/user-attachments/assets/3274127d-842f-4025-8d38-2cf230c6e4af" />

```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/desktop/runimage-desktop.sh | bash
```
*First Launch can take a while as it downloads Desktop packages from Arch Repositories in background.
___


## Caja GUI file manager and Engrampa Archiver (zip, rar, 7zip etc) via Runimage
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/caja/caja-install.sh | bash
```
Mouse / Keyboard Recommended

---

<h2>
  <img width="32" height="32" 
       src="https://github.com/user-attachments/assets/07ffca9d-c63b-4b63-8fcd-628e16abc85e" 
       alt="Firefox logo" 
       style="vertical-align: middle; margin-right: 8px;" />
  Firefox  Browser
</h2>

*(Compatibility varies -- SM8550/ODIN 2 and RK3588 Worked , RK3566 didn't work -- 4gb RAM seems to be minimum)

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/firefox.sh  | bash
```
--- 
<h2>
  <img width="32" height="32" 
       src="https://github.com/user-attachments/assets/c5a0b12f-047f-4a8a-9fc9-1c50098aca49" 
       alt="Brave logo" 
       style="vertical-align: middle; margin-right: 8px;" />
  Brave Browser
</h2>


* Worked on Powkiddy X55/2GB and Orange Pi 5/4gb in Panfrost mode.
* Rockchip SOC users need Panfrost Mode
* Includes Launchers for Geforce Now, Xcloud, and Amazon Luna
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/brave/brave.sh | bash
```

---
<h2>
  <img width="32" height="32" 
       src="https://github.com/user-attachments/assets/b23f1d43-16ab-4016-9981-fd69446cd6ec"
       src="https://github.com/user-attachments/assets/21f86d42-384b-4908-94fb-7a8290f08a89"
       alt="Librewolf + YT logo" 
       style="vertical-align: middle; margin-right: 8px;" />
LibreWolf + YouTube Leanback (TV UI)
</h2>



Launches LibreWolf with a custom profile tailored for YouTube Leanback (TV UI).  
Includes GPTK mappings for full gamepad navigation in Youtube Leanback.

*(Recommended for Lower end devices)

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/librewolf/librewolf.sh | bash
```

---
<h2>
  <img width="32" height="32" 
       src="https://github.com/user-attachments/assets/7db1dee1-49ad-4df7-8f40-b17d9646a01e"
       alt="Chromium" 
       style="vertical-align: middle; margin-right: 8px;" />
Chromium (Alpine Chroot)
</h2>


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


<h2>
  <img width="64" height="64" 
       src="https://github.com/user-attachments/assets/0a6f97d7-a4f4-4bd2-91f2-985417a2f1fc"
       alt="Kodi" 
       style="vertical-align: middle; margin-right: 8px;" />
Kodi Media Center in Arch Container
</h2>

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
## ES MUSIC PACK (Music from Batocera, Knulli, and Reg-Linux)

```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/music.sh | bash
```
---
## Emudeck Store, Batocera, & Reg-Linux free Homebrew Roms pack -- Roms that come with those distros

```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/freebatroms.sh | bash
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


---
## 🧰 PKGX (CLI Tool Manager)

Lightweight CLI package manager from [pkgx.dev](https://pkgx.dev/pkgs/).

**Install via SSH:**
```
curl -L https://github.com/profork/ROCKNIX-apps/raw/main/pkgx/pkgx.sh | bash
```



