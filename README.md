# Kilimanjaro OS

Project source: [Gerald-Poka/Kilimanjaro-Operating-System](https://github.com/Gerald-Poka/Kilimanjaro-Operating-System).
Author: Gerald Ndyamukama · geraldndyamukama39@gmail.com.
This repository contains source and project assets, not a production-certified
OS. Generated ISOs, VM disks, build trees and private key material are excluded.

## Important disclaimer — development software

Kilimanjaro OS is an independent, community-developed project. The current
build is experimental, not a certified secure or stable release, and is not
recommended for mission-critical, safety-critical or production use.

**No warranty:** to the extent permitted by applicable law, original Kilimanjaro
code is provided as-is, without express or implied warranties, including
merchantability or fitness for a particular purpose. Warranty and liability
terms for that code are governed by [GPL-3.0, sections 15–17](LICENSE) and
applicable law. Third-party components retain their own terms.

**Use with care:** installation, USB flashing, partitioning, updates and recovery
can erase data, interrupt work or make a system unbootable. Verify backups and
the destination device before writing anything; begin with a disposable VM or
spare test machine. Hardware, drivers, games and applications are not guaranteed
to work. A checksum or signed Secure Boot chain does not certify the entire OS.

**No guaranteed support:** there is no professional support contract,
response-time commitment or guaranteed maintenance/security-update schedule.
Kilimanjaro claims no endorsement by Debian, KDE or other upstream vendors.

This notice does not limit rights or obligations that cannot lawfully be
excluded, change component licenses, or guarantee immunity from legal claims.
Obtain qualified legal advice for your jurisdiction before commercial or broad
public distribution. See [licensing scope](LICENSING.md),
[release limitations](docs/READINESS-REVIEW.md) and
[publication requirements](docs/PUBLISHING.md).

The React website is in [website/](website/README.md). Run `npm ci` and
`npm run dev` there for a local preview. It reuses the OS wallpapers, documents
development status, and supports staging the checksummed development ISO for
local downloads. It has not been published to a public domain.

Before making the source public or distributing an ISO, follow the
[publication and release checklist](docs/PUBLISHING.md). Original-project
artwork/documentation permissions and release-key setup still require attention; upstream
components retain their own licenses and credits.

Original Kilimanjaro code is **GPL-3.0-only**, copyright 2026 Gerald Ndyamukama.
Read [LICENSE](LICENSE) and [licensing scope](LICENSING.md). The current
[readiness review](docs/READINESS-REVIEW.md) records fixes, test evidence and
remaining release gates. This license does
not replace upstream licenses or automatically license all artwork in the ISO.

The goal is installation on physical Intel/AMD PCs. See the
[hardware qualification plan](docs/HARDWARE-QUALIFICATION.md): compatibility
with Ubuntu 26.04-class PCs is a target, not a guarantee. Physical testing is
deferred; the current PC and physical USB devices must not be overwritten.

Kilimanjaro OS is a lightweight, offline-first desktop operating system for Tanzanian schools and offices. This repository implements the Debian-based path selected in the project blueprint while keeping Kilimanjaro's identity, policies, package selection, and release pipeline under project control.

The current `0.1.0` milestone is a development image. The ISO builds, passes the offline BIOS live-boot test, and has booted in a Secure Boot-enabled UEFI VM. The earlier initramfs failure was fixed by preserving root ownership in the container build volume. Installation/reboot qualification and physical hardware testing are still required before a production release.

## Current baseline

- Debian 13 `trixie`, amd64
- Linux 6.12 LTS series through Debian's `linux-image-amd64` package
- systemd with Kilimanjaro service policy
- KDE Plasma 6, Xorg, and SDDM with the Kilimanjaro global theme
- KDE System Settings and Info Center, with Kilimanjaro branding in About this System
- KDE Discover with APT/package and Flatpak backends for software browsing and updates
- Timeshift system snapshot/recovery utility (snapshot storage and schedules must be configured)
- PulseAudio-compatible volume mixer (`pavucontrol`) on the PipeWire audio stack
- NVIDIA Settings control panel package; a matching NVIDIA driver and NVIDIA GPU are required
- ASUS ROG Control Center is not included yet: upstream does not officially support Debian, so it needs a tested, model-aware package before we ship it
- Konsole pinned to the panel and an “Open in Konsole” action when right-clicking folders in Dolphin
- Kiswahili locale, dictionary, and project-facing defaults with British English UI fallback
- Firefox enterprise policies for reduced background traffic and Tanzanian government bookmarks
- disabled APT background downloads and NetworkManager connectivity checks
- metered-connection defaults, interface-counter snapshots, and an on-demand
  per-process live network view in the KDE system tray
- LibreOffice, Kiwix, GCompris, TuxMath, Klavaro, and core security tools
- Kilimanjaro Welcome with authenticated Daily, Office, Development, Gaming,
  Creator, Communication, and Ultimate software profiles
- KDE Discover with APT and Flatpak support, KDE Connect, VLC, and OBS Studio
- six coordinated Kilimanjaro wallpapers (the original plus five alternate scenes), emblem, dark color scheme, boot splash, login styling, and desktop layout
- hybrid BIOS/UEFI ISO generation with Debian's signed shim and GRUB in the UEFI boot chain, SHA-256 checksums, and optional GPG signing

Debian 13 was selected because it is the current stable release and supports the target amd64 hardware class. The suite is pinned by codename (`trixie`) rather than the moving `stable` alias.

## What this milestone does not claim

- The ISO has not yet passed the hardware matrix in the blueprint.
- A Kilimanjaro-branded Calamares installer completed an offline UEFI VM install;
  the installed disk booted and accepted console login. Installed graphical
  desktop qualification, BIOS installation/reboot and physical hardware tests
  remain pending. Treat this as a development image, not a production release.
- The ISO carries Debian's Microsoft-trusted signed shim/GRUB boot chain; static
  signature checks pass, and `mokutil --sb-state` reports `SecureBoot enabled`
  in the UEFI live VM. Installed-disk UEFI boot was tested, but broader
  installed-system qualification remains. Kilimanjaro's
  own release ISO is checksummed but not GPG-signed until a release key is set.
- Timeshift is available, but automatic snapshot policy and restore testing are not complete; it is not a substitute for a user-data backup.
- ASUS ROG controls/fan profiles and laptop graphics-mode switching are not yet integrated.
- The first-boot component applies safe non-interactive defaults and the English
  Kilimanjaro Welcome GUI is implemented; complete Kiswahili translation remains.
- Interface byte counters are recorded periodically. The tray monitor shows live
  per-process rates only while open (NetHogs requires administrator approval);
  persistent per-process history is not recorded.
- A signed project APT repository, metapackage, complete branded artwork, USB
  scanning workflow, and offline update bundles remain roadmap items.

## Updates, recovery, sound, and graphics

Plasma X11 is the development default: its desktop has been visually verified
in the Secure Boot VM. Wayland remains available but is not the default while
its black-screen behavior under software-emulated virtual graphics is investigated.

KDE Discover is packaged with the APT/PackageKit backend and Flatpak backend for
normal online software and update operations. The image deliberately disables
background APT timers to avoid unexpected metered-data use; users should open
Discover and choose Updates when they are ready to update.

Timeshift is included for system snapshots. It is not preconfigured to consume
disk space automatically: after installing Kilimanjaro, choose a suitable
snapshot destination and schedule in Timeshift. Validate restore on a test
machine before relying on it, and keep personal files backed up separately.

Audio uses PipeWire with its PulseAudio compatibility service. KDE's panel
provides everyday volume control, while `pavucontrol` exposes per-application
streams and input/output device selection.

The network monitor appears in KDE's system tray. Open it and choose **Start
monitoring** to authorize NetHogs; it then shows live sent/received rates by
process. Closing the window stops capture. It does not save per-process traffic
history, and the periodic interface-byte snapshots remain separate.

`nvidia-settings` is included for systems with a supported NVIDIA driver/GPU;
this is the control panel, not the proprietary kernel driver. NVIDIA driver
installation and Secure Boot module signing still need hardware-specific
qualification. The VM uses virtual graphics, so the NVIDIA panel cannot be
meaningfully tested there.

Konsole is in the application launcher and pinned to the panel. Dolphin's
folder context menu includes a top-level **Open in Konsole** action. Right-click
a folder in Dolphin to open a terminal with that folder as its working directory.

The ROG Control Center / `asusctl` stack is not shipped in this Debian-based
image yet. It controls device-specific laptop features, and upstream documents
Debian as unsupported; Kilimanjaro will add it only after packaging and testing
on supported ASUS ROG models. See the [ROG stack compatibility notes](https://github.com/OpenGamingCollective/asusctl#installation-and-setup).

## Kilimanjaro wallpaper collection

The desktop ships the original sunset wallpaper plus five matching alternatives:
Dawn, Blue Hour, Green Morning, Uhuru Glacier, and Savanna Gold. Each is a
separate wallpaper entry in KDE's Desktop and Wallpaper settings, so users can
switch images without replacing files or changing the system theme. The source
art is kept in `overlay/usr/share/wallpapers/` and packaged into the next ISO.

## Repository layout

```text
config/build.env          Build identity and Debian suite
config/packages/          Auditable package selections
overlay/                  Files copied into the target root filesystem
scripts/01-bootstrap.sh   Minimal Debian root filesystem
scripts/02-packages.sh    Desktop and application package layer
scripts/03-configure.sh   Kilimanjaro identity and policy layer
scripts/04-image.sh       SquashFS and hybrid ISO assembly
scripts/05-release.sh     Checksums and optional signatures
tests/validate.sh         Non-privileged source validation
```

For day-to-day editing, container rebuilds, automated tests, and BIOS/UEFI VM commands, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). The visual language and UI rules are recorded in [docs/DESIGN.md](docs/DESIGN.md). The application and profile backlog is maintained in [docs/SOFTWARE-ROADMAP.md](docs/SOFTWARE-ROADMAP.md).

See [installation and acceptance tests](docs/INSTALLATION.md) before using the
installer. A local React website preview is implemented in `website/`; public
release publishing remains deferred until OS release qualification.

## Validate the source tree

```bash
make validate
```

This checks shell syntax, Firefox policy JSON, package-list formatting, the pinned architecture/release, and required overlay files. It does not download packages or require root.

## Build on Debian or Ubuntu

The build needs root, at least 60 GiB free disk, and preferably 8 GiB RAM.

```bash
sudo apt update
sudo apt install -y \
  debootstrap squashfs-tools xorriso grub-common grub-pc-bin \
  grub-efi-amd64-bin mtools dosfstools rsync gnupg make sbsigntool

make host-check
sudo make bootstrap
sudo make package-check
sudo make iso
```

`package-check` refreshes the target APT metadata and resolves the entire package selection without downloading or installing the payload.

Artifacts are written to `output/`. Re-running the build reuses the completed rootfs. Use `sudo make clean` only when a clean rebuild is required.

## Build from Fedora, Nobara, or another Linux host

Podman is the default container engine:

```bash
make container-iso
```

The builder container is privileged because `debootstrap`, chroot mounts, and GRUB image creation require Linux mount capabilities. Review `Containerfile.build` and the scripts before running it. Docker can be selected with:

```bash
make container-iso CONTAINER_ENGINE=docker
```

For a fast rebuild after editing overlays or branding, use `make container-repack`. After changing package manifests, use `make container-update`.

## Sign a release

Set the GPG key fingerprint or key ID only for a controlled release build:

```bash
sudo KILIMANJARO_GPG_KEY='<release-key-fingerprint>' make release
```

Without that variable, the release stage writes `SHA256SUMS` but deliberately leaves the artifacts unsigned.

Container builds keep `build/` in a persistent Docker/Podman volume named
`kilimanjaro-build`. This is intentional: the generated Linux root filesystem
needs Unix ownership and setuid metadata, which some workspace bind mounts do
not preserve. Override `KILIMANJARO_BUILD_VOLUME` to use a different volume.

## Test the generated ISO

The generated ISO has BIOS and UEFI El Torito entries. Static signatures and
checksums pass, the offline BIOS smoke test confirms SDDM and Plasma, and the
UEFI live guest reports Secure Boot enabled. Installation and disk-only reboot
checks are separate release gates; see the installation guide for their procedure.

Run the complete automated test stack and then open an interactive VM with:

```bash
make test
make vm       # BIOS
make vm-uefi  # UEFI
make vm-secureboot  # Secure Boot with enrolled Microsoft keys
```

Next, use the blueprint's physical BIOS, UEFI, minimum-hardware, Wi-Fi, and USB-modem matrix. Do not distribute an image merely because it boots in a VM.

## Project decisions still needed

- final branding, logo, palette, and release codename
- project software license and contributor policy
- public domain names and hosting for the website, repository, support, and issue tracker
- GPG release-key custody and rotation procedure
- redistribution approval for OnlyOffice, TurboWarp, and curriculum content

See [docs/ROADMAP.md](docs/ROADMAP.md) for implementation status and the next milestones.
