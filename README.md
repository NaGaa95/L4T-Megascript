### DISCLAIMER:
Unofficial L4T-Megascript fork, USE AT YOUR OWN RISK <br/>
Some of the scripts shown here *may* screw up your installation if you're not using Tegra hardware. Most of them should be fine to use on other systems, but double-check the source code first.
In addition, keeping your Tegra system overclocked too often or rebuilding programs too often might shorten the lifespan of your system or the SD card.
<p align="center">
    <img src="https://github.com/cobalt2727/L4T-Megascript/raw/master/assets/L4T_Megascript-logo.svg" height=256 alt="L4T-Megascript Logo"
</p>

<p align="center">All-in-one installer and updater for popular programs on L4T Ubuntu with no prior knowledge of Linux needed
<p align="center">
  <a href="https://github.com/cobalt2727/L4T-Megascript/wiki">
    Scripts List</a>
  |
  <a href="https://discord.gg/abgW2AG87Z">
    Join the <img src="https://img.shields.io/discord/719014537277210704.svg?color=7289da&label=Discord%20server&logo=discord" alt="Join the Discord server"></a>
  |
  <a href="https://github.com/cobalt2727/L4T-Megascript/issues">
    Report an error</a>
  |
  <a href="https://github.com/cobalt2727/L4T-Megascript/discussions/categories/ideas">
    Submit a suggestion</a>
  |
  <a href="https://github.com/cobalt2727/L4T-Megascript/pulls">
    Submit a script</a>

## Install/run the Megascript+ :
### Try without installing
﻿
Run this in a terminal - launches the GUI once without changing anything :
```
bash <( wget -O - https://raw.githubusercontent.com/NaGaa95/L4T-Megascript/master/core_refactor2.sh ) gui
```
### Permanent Installation
﻿
Replace the system L4T-Megascript .desktop file  :
```
sudo wget -O /usr/share/applications/L4T-Megascript.desktop \
  https://raw.githubusercontent.com/NaGaa95/L4T-Megascript/master/assets/L4T-Megascript.desktop
```
Then log out and back in. The L4T-Megascript shortcut in your start menu will now launch this fork.

Scripts Added / Updated : 
```
- Emulators :
RPCS3
Vita3K
PPSSPP
Duckstation
MelonDS
mGBA
Cemu
Rosalie MupenGUI
NooDS
Play!
Xenia Edge
Xemu
Steam ARM - Switchdeck
- Native ARM Port / Recomp
MarathonRecomp
UnleashedRecomp
BanjoRecomp
Shipwright
Starship
Dusk
GhostShip
OpenMohaa
Xash3D
- Extras
LSFG-VK
```
Support Ubuntu Noble / Fedora 42

Report me if you have any issue with the scripts added here

## Need some help or want to contribute?
You're in luck - we've got a Discord server: [![Discord invite](https://discord.com/assets/ff41b628a47ef3141164bfedb04fb220.png)](https://discord.gg/abgW2AG87Z "Discord server invite link") <Br>
[Click to join](https://discord.gg/abgW2AG87Z) <Br>

## Credits
- STJr: Developers, SRB2
- Kart Krew: Developers, SRB2Kart
- RetroPie: Developers, RetroPie (who would've guessed?)
- dolphin-emu: Developers, Dolphin
- moonlight-stream: Creators and developers of Moonlight-QT
- lemon-sherbet: Developer, Celeste Classic port
- Acry: Developer, Flappy Bird port
- SuperTux: Developers, SuperTux2
- n64decomp: Responsible for the SM64 Decompilation Project
- sm64pc: Adapted the SM64 Port to work with ARM64 devices
- OpenMW: Developers, OpenMW
- mrcmunir : RPCS3 & Others
- SildurFX : Switchdeck
- Masies : LSFG-VK
- many more!
