# Kilimanjaro Ultimate software roadmap

Kilimanjaro Ultimate is intended to be a complete workstation for everyday use,
AI-assisted development, gaming, meetings, writing, and content production. The
distribution must remain maintainable: open-source essentials can ship in the
image, while proprietary applications are installed with explicit consent from
signed vendor repositories, sandboxed catalogues, or official download pages.

## Delivery rules

- never embed user accounts, API keys, or authentication tokens
- never execute package names or commands supplied by GUI input
- prefer Debian packages for hardware-integrated tools
- use Flatpak for suitable proprietary desktop applications
- use signed official repositories for Chrome and Cursor
- require PolicyKit administrator authentication for system changes
- detect graphics hardware before choosing NVIDIA, AMD, or Intel driver stacks
- keep vendor-specific laptop controls optional and hardware-gated; do not ship an unverified daemon on every machine
- show live-session users that installations are temporary

## Already in the base image

The profiles below describe what each profile *adds*. These capabilities are
part of every image and must not be re-implemented by a profile:

- Discover with the APT/PackageKit backend and the Flatpak backend
- Firefox ESR with enterprise policies, LibreOffice, VLC, OBS Studio
- KDE Connect, Thunderbird-style mail is **not** shipped (see gaps below)
- printing (CUPS, network discovery, PDF output) and scanning
- archive tools (7-Zip, RAR), extended media codecs
- Orca screen reader, KMag magnifier, `espeak-ng`
- on-screen keyboard and IBus input methods
- SMB/CIFS and NFS clients, VPN front ends, broadband modem support
- Kiswahili and British English spellcheck, Noto/Liberation/Carlito/Caladea fonts
- firmware updates over LVFS, plus disk/SMART/sensor/link/graphics diagnostics
- Timeshift, `pavucontrol`, Ark, Okular, Dolphin, Konsole, Kate, Gwenview, KCalc

Known gaps in the base image, recorded so a profile does not silently depend on
them: no mail client, no NVIDIA proprietary driver, no offline content packs or
seeded package cache, and no content-pack manager. The "offline-first"
description is a direction, not a delivered capability.

## Software profiles

### Daily Essentials

KDE Connect, VLC, Discover, Flatpak, password management, disks, partitions,
remote desktop, downloads, archives, screenshots, PDF and calculator tools.

### Office and Writing

LibreOffice, WPS Office vendor download, Okular, OCR, scanning, dictionaries,
reference tools, PDF workflows, Microsoft-compatible fonts and Markdown tools.

### AI and Development

ChatGPT/Codex, Claude Code, Gemini CLI, Cursor, Git, GitHub CLI, Python, Node.js,
Java, Go, Rust, C/C++, containers, debuggers and modern build systems. Local AI
with Ollama remains an optional later addition because model storage is large.

### Gaming Ready

**Shipped in the image:** Steam, Wine with 32-bit support, Winetricks, GameMode,
MangoHud, Vulkan tools, 32-bit graphics support (the build enables `i386`
multiarch, without which `steam` has no installation candidate), and the
proprietary NVIDIA driver with `dkms` plus kernel headers so its module builds.

**Still to qualify:** controllers, per-title testing, and the anti-cheat
reality. Many Windows titles ship kernel-level anti-cheat that refuses to run on
Debian regardless of kernel version; that is an upstream limitation, not
something the image can fix. Gamescope is absent because Debian 13 does not
package it and nothing selects it automatically; users can opt in with
`sudo apt install -t trixie-backports gamescope`. Lutris, Heroic and
Bottles remain optional. Kernel changes require separate stability testing, and
the kernel series is coupled to the NVIDIA driver: 7.x has no working packaged
driver, so raising the kernel means losing proprietary NVIDIA or carrying a
private patch against proprietary source.

### Creator Studio

**Shipped in the image:** OBS Studio, VLC, FFmpeg, Kdenlive, Blender, Krita,
GIMP, Inkscape, Audacity and the extended Noto font set.

**Still to qualify:** HandBrake, hardware encoding (depends on qualified GPU
hardware) and game-capture integration.

### Programming

**Shipped in the image:** `build-essential`, `git`, `pkg-config`, `cmake`,
`ninja-build`, `gdb`, `python3-dev`, `python3-pip`, `python3-venv` — enough to
build and debug C, C++ and Python offline.

**Deliberately excluded to bound image size:** Rust (`rustc` plus `cargo` alone
is around 1.5 GB installed), Go, a JDK and Node. Install on demand. Container
runtimes (Podman/Docker) are also not baked in yet.

### Meetings and Communication

Zoom, Slack, Teams and Google Meet launchers, Discord, Spotify, KDE Connect,
PipeWire screen sharing, camera/microphone checks and virtual-camera support.

### Kilimanjaro Ultimate

All profiles installed together on systems with sufficient storage. The setup
UI must show the expected download and installed sizes before installation.

## Reliability work still required

- Calamares installation with encryption and dual-boot tests
- configure Timeshift snapshots and test restore/recovery on disposable systems
- Kilimanjaro update and recovery workflow with signed updates and offline bundles
- validate ASUS `asusctl` / ROG Control Center packaging on Debian before offering it for supported ASUS ROG hardware
- Secure Boot and NVIDIA module-signing workflow
- driver rollback and rescue graphics mode
- package repository ownership and signing
- application compatibility tests after every image build
- real AMD, Intel, NVIDIA, laptop, desktop and controller hardware matrix
