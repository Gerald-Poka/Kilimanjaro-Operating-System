# Kilimanjaro OS implementation roadmap

This roadmap translates the blueprint into testable delivery gates. A phase is complete only when its acceptance checks pass; dates can be assigned after the first full build establishes real effort and hardware constraints.

## Milestone 0 Live image foundation

Status: implementation and initial VM smoke test complete; physical hardware qualification remains.

- reproducible Debian `trixie` amd64 rootfs pipeline
- explicit package manifests
- KDE Plasma 6/Xorg live desktop
- Kilimanjaro `os-release`, locale, timezone, hostname, and service policy
- low-bandwidth APT, NetworkManager, and Firefox defaults
- hybrid BIOS/UEFI GRUB ISO assembly
- checksum and optional GPG signing hooks
- automated offline QEMU boot smoke test
- Plasma 6 desktop, original wallpaper/emblem, global color scheme, SDDM, Plymouth, and GRUB branding
- KDE System Settings, Info Center, and Kilimanjaro creator/product metadata
- Discover APT/Flatpak update paths, Timeshift recovery snapshots, PulseAudio-compatible mixer, and NVIDIA Settings UI
- Dolphin directory context action to open the selected folder in Konsole

Exit gate status:

- [x] source validation passes
- [x] clean container build completes
- [x] ISO boots in QEMU with 2 GiB RAM
- [x] SDDM starts for the selected `graphical.target`
- [x] visually verify the Plasma X11 desktop in the Secure Boot VM
- [ ] exercise all packaged applications
- [ ] verify Kiswahili UI behavior and English fallback with native speakers
- [ ] capture an idle outbound-network trace confirming the configured APT and connectivity-check policy
- [ ] complete the physical hardware matrix
- [ ] verify Timeshift snapshot creation and restore on a disposable VM install
- [ ] verify PulseAudio-compatible audio controls with virtual and physical audio devices
- [ ] verify NVIDIA Settings and driver stack on supported NVIDIA hardware
- [ ] package and validate ASUS ROG Control Center on supported ASUS models before inclusion

## Milestone 1 Installable development image

Status: initial Calamares integration is in the ISO and the live system passes
the automated QEMU boot check; end-to-end installation and first-boot checks
remain open.

- maintain Kilimanjaro Calamares settings and branding as source-controlled overlays
- support BIOS and UEFI installation
- add a safe partitioning test matrix, including encrypted installs
- separate live-session behavior from installed-system behavior
- add installer-specific QEMU tests with disposable virtual disks
- run end-to-end installs to disposable BIOS and UEFI VM disks and reboot from disk
- verify installed branding, desktop, user account, networking, and first boot

## Milestone 1A Kilimanjaro Welcome and software profiles

Status: first functional implementation complete; installation testing remains.

- native Qt welcome experience launched on first Plasma login
- curated Daily, Office, AI/Development, Gaming, Creator, Communication, and Ultimate profiles
- strict root installer that accepts only approved profile/application identifiers
- PolicyKit authentication and visible installation logs
- signed vendor repository flows for Chrome and Cursor
- sandboxed Zoom, Slack, Spotify, Discord, Heroic, and Bottles installation through Flathub
- official-download routing for WPS Office and ChatGPT/Codex
- live-session persistence warning and local hardware summary

Exit gate status:

- [x] source, JSON, Python, shell, and PolicyKit policy validation
- [ ] resolve every optional profile package against Debian `trixie`
- [ ] exercise every profile in a disposable installed VM
- [ ] complete Kiswahili translation
- [ ] add GPU-aware NVIDIA/AMD/Intel driver selection

## Milestone 2 Owned package and update chain

Status: not started.

- build `kilimanjaro-base`, `kilimanjaro-desktop`, and archive-keyring packages
- publish a staging aptly repository
- define package pinning and Debian security fallback policy
- implement release-key custody, rotation, and revocation procedures
- implement signed offline update bundles

## Milestone 3 User experience and localization

Status: not started.

- refine the implemented Plasma, Plymouth, GRUB, SDDM, wallpaper, and icon design after user testing
- bilingual first-boot GUI for profile, language, content packs, and modem support
- translation catalog and review workflow
- data-usage panel UI with daily and monthly totals
- content-pack manager for Kiwix and Kolibri assets

## Milestone 4 Security and release candidate

Status: not started.

- removable-media mount and scanning design that does not run long work in udev
- LibreOffice macro policy and document compatibility test corpus
- AppArmor enforcement and exception review
- outbound-network audit with per-process evidence
- Debian-signed Secure Boot chain is implemented and the UEFI live VM reports
  SecureBoot enabled; qualify installed-system boot, physical firmware, and
  third-party kernel-module signing before release
- full physical hardware matrix and pilot deployment
