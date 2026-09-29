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

Steam, Proton tooling, Wine, Winetricks, Lutris, Heroic, Bottles, GameMode,
MangoHud, Vulkan tools, 32-bit graphics support, controllers and hardware-aware
GPU drivers. Gamescope requires a future Kilimanjaro repository package because
Debian 13 does not currently provide it. Kernel changes require separate
stability testing.

### Creator Studio

OBS Studio, VLC, FFmpeg, Kdenlive, Blender, Krita, GIMP, Inkscape, Audacity,
HandBrake, hardware encoding and game-capture integration.

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
