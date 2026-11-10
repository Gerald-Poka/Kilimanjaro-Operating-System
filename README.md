# Kilimanjaro OS

Project source: [Gerald-Poka/Kilimanjaro-Operating-System](https://github.com/Gerald-Poka/Kilimanjaro-Operating-System).
Author: Gerald Ndyamukama · geraldndyamukama39@gmail.com.
This repository contains source code and project assets for an experimental OS;
it is not a production-certified release. Generated ISOs, VM disks, build trees,
and private key material are excluded.

## Important disclaimer — development software

Kilimanjaro OS is an independent project. This development build is experimental,
not a certified secure or stable release, and is not recommended for
mission-critical, safety-critical, or production use.

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
Kilimanjaro OS is not affiliated with or endorsed by Debian, KDE, or other
upstream projects.

This notice does not limit rights or obligations that cannot lawfully be
excluded, change component licenses, or guarantee immunity from legal claims.
Obtain qualified legal advice for your jurisdiction before broad or commercial
distribution. See [licensing scope](LICENSING.md),
[release limitations](docs/READINESS-REVIEW.md) and
[publication requirements](docs/PUBLISHING.md).

The React website is in [website/](website/README.md). Run `npm ci` and
`npm run dev` there for a local preview. It reuses the OS wallpapers, documents
development status, and supports staging the checksummed development ISO for
local downloads. It has not been published to a public domain.

The source repository is public. Before distributing an ISO or making other
public releases, follow the [publication and release checklist](docs/PUBLISHING.md).
Artwork and documentation permissions, third-party notices, and release-key
setup still need review; upstream components retain their own licenses and
credits.

Original Kilimanjaro code is **GPL-3.0-only**, copyright 2026 Gerald Ndyamukama.
Read [LICENSE](LICENSE) and [licensing scope](LICENSING.md). The current
[readiness review](docs/READINESS-REVIEW.md) records fixes, test evidence and
remaining release gates. This license does
not replace upstream licenses or automatically license all artwork in the ISO.

The goal is installation on physical Intel/AMD PCs. See the
[hardware qualification plan](docs/HARDWARE-QUALIFICATION.md): compatibility
with Ubuntu 26.04-class PCs is a target, not a guarantee. Physical testing is
deferred. Do not install on a primary computer or write to a physical USB
device without explicit approval and a verified backup.

Kilimanjaro OS is a Debian-based desktop project for Tanzanian schools and
offices. Supporting offline use is a design goal, not a claim that offline
updates or content packs are already available. This repository implements the
Debian-based path selected in the project blueprint while keeping Kilimanjaro's
identity, policies, package selection, and release pipeline under project
control.

The `0.1.0` milestone is a development image. A previously built ISO passed an
offline BIOS live-boot test and booted in a Secure Boot-enabled UEFI VM. The
source has changed since that image was built, so those results do not validate
the current source; rebuild and test the image before relying on them.
Installation/reboot qualification and physical hardware testing are still
required before a production release.

## Current baseline

- Debian 13 `trixie`, amd64
- Debian's stable 6.12 LTS kernel series via the `linux-image-amd64` package, with matching headers. 6.12 is the newest kernel any NVIDIA driver in any Debian suite builds against, which is what makes the proprietary driver below work. The kernel stays Debian-packaged and Debian-signed, so the existing shim/GRUB Secure Boot chain keeps validating it. The target deployment runs with Secure Boot disabled in the PC BIOS, so the driver's self-signed DKMS MOK needs no enrolment step
- systemd with Kilimanjaro service policy
- KDE Plasma 6, Xorg, and SDDM with the Kilimanjaro global theme
- KDE System Settings and Info Center, with Kilimanjaro branding in About this System
- KDE Discover with the APT/PackageKit backend and the Flatpak backend, so
  software browsing and updates have a working APT source
- Timeshift system snapshot/recovery utility (snapshot storage and schedules must be configured)
- PulseAudio-compatible volume mixer (`pavucontrol`) on the PipeWire audio stack
- printing via CUPS with automatic network-printer discovery, PDF printing, and
  a scanner front end (`sane-utils`)
- **Programming pillar**: a working offline C/C++/Python toolchain —
  `build-essential`, `git`, `cmake`, `ninja-build`, `pkg-config`, `gdb`,
  `python3-dev`, `pip` and `venv`. The large language toolchains (Rust, Go, a
  JDK, Node) are intentionally excluded to keep the image reasonable and are
  installable on demand
- **Content creation pillar**, baked in so no download is needed: `ffmpeg`,
  GIMP, Inkscape, Krita, Kdenlive, Audacity, Blender, `cups-filters` and the
  extended Noto font set
- **Gaming pillar**: Steam, Wine with 32-bit support (`wine32`), Winetricks,
  GameMode, MangoHud, Vulkan tooling, and the proprietary NVIDIA driver with its
  DKMS build support. Steam and most Windows titles need 32-bit libraries, so
  the build enables `i386` multiarch; without it `steam` has no installation
  candidate at all. `gamescope` is not in Debian 13 and is left to an explicit
  `apt install -t trixie-backports gamescope`
- accessibility: Orca screen reader, KMag magnifier and `espeak-ng` speech
- on-screen keyboard and input-method support for touch and tablet hardware
- ASUS ROG Control Center is not included yet: upstream does not officially support Debian, so it needs a tested, model-aware package before we ship it
- Konsole pinned to the panel and an “Open in Konsole” action when right-clicking folders in Dolphin
- Kiswahili locale, dictionary, and project-facing defaults with British English UI fallback
- Kiswahili and British English spellcheck dictionaries, so English documents are
  not spellchecked against the Kiswahili dictionary
- Firefox enterprise policies for reduced background traffic and Tanzanian government bookmarks
- disabled APT background downloads and NetworkManager connectivity checks
- metered-connection defaults, interface-counter snapshots, and an on-demand
  per-process live network view in the KDE system tray
- SMB/CIFS and NFS clients for school file servers, VPN front ends, and broadband
  modem support
- firmware updates over LVFS (`fwupd`), plus disk, SMART, sensor, network and
  graphics diagnostics used for hardware reporting
- LibreOffice, Kiwix, GCompris, TuxMath, Klavaro, and core security tools
- Kilimanjaro Welcome with authenticated Daily, Office, Development, Gaming,
  Creator, Communication, and Ultimate software profiles
- KDE Connect, VLC, OBS Studio, archive tools (7-Zip, RAR), and extended media codecs
- guest integration agents for QEMU/KVM, VMware and VirtualBox
- eleven coordinated Kilimanjaro wallpapers in source, emblem, dark color scheme, boot splash, login styling, and desktop layout
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
  scanning workflow, and offline update bundles remain roadmap items. The
  repository tooling is built and signed, but is inert until hosting exists:
  the image ships no archive source, so `kilimanjaro-base` and
  `kilimanjaro-desktop` cannot yet update themselves on an installed system.
- Printing is packaged and enabled, but no physical printer or scanner has been
  tested. Network-printer discovery uses mDNS, so `avahi-daemon` is enabled for
  that reason; disable it if site network policy forbids mDNS.
- Security updates are opt-in. `unattended-upgrades` is installed and scoped to
  Debian security archives only, but `APT::Periodic` stays at `0`, so nothing
  downloads or installs without the user's decision.

## Updates, recovery, sound, and graphics

Debian package updates work through `sudo apt update` followed by
`sudo apt upgrade`, or KDE Discover. Kilimanjaro-specific base/desktop `.deb`
packages and signed repository tooling are implemented, and the image can now
activate the archive channel, but public project hosting does not exist yet, so
the channel ships disabled. See
[APT update implementation and activation](docs/APT-UPDATES.md).

Plasma X11 is the development default: its desktop has been visually verified
in the Secure Boot VM. Wayland remains available but is not the default while
its black-screen behavior under software-emulated virtual graphics is investigated.

KDE Discover is packaged with the APT/PackageKit backend and the Flatpak backend.
The APT backend is what makes Debian software visible; without it Discover lists
nothing, because the image ships no Flatpak remote. The image deliberately
disables background APT timers to avoid unexpected metered-data use; users
should open Discover and choose Updates when they are ready to update.

For unattended security updates, `unattended-upgrades` is installed and limited
to the Debian security archive, with automatic reboot disabled so an update
cannot interrupt a lesson. It still runs only on request:

```
sudo systemctl start unattended-upgrades.service
```

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

NVIDIA GSP firmware is included so display output and `nouveau` work on NVIDIA
hardware. The proprietary driver **is** shipped together with `nvidia-settings`
in the gaming pillar, because Linux 6.12 is the newest kernel any NVIDIA driver
in any Debian suite builds against: on a 7.x kernel there is no working packaged
driver at all. AMD and Intel machines are unaffected and continue to use Mesa.

The driver is built locally by `dkms` and signed with a self-signed MOK. The
target deployment runs with Secure Boot disabled in the PC BIOS, so no signature
is enforced and the modules load with no enrolment step. If you enable Secure
Boot on a machine, the NVIDIA modules will be rejected until that MOK is
enrolled, so treat Secure Boot as unsupported while the proprietary driver
ships.

Konsole is in the application launcher and pinned to the panel. Dolphin's
folder context menu includes a top-level **Open in Konsole** action. Right-click
a folder in Dolphin to open a terminal with that folder as its working directory.

The ROG Control Center / `asusctl` stack is not shipped in this Debian-based
image yet. It controls device-specific laptop features, and upstream documents
Debian as unsupported; Kilimanjaro will add it only after packaging and testing
on supported ASUS ROG models. See the [ROG stack compatibility notes](https://github.com/OpenGamingCollective/asusctl#installation-and-setup).

## Kilimanjaro wallpaper collection

The source collection contains the original sunset wallpaper plus ten alternatives:
Dawn, Blue Hour, Green Morning, Uhuru Glacier, Savanna Gold, Moonlight, Forest Mist,
Sea of Clouds, Amber Highlands, and Violet Twilight. Each is a
separate wallpaper entry in KDE's Desktop and Wallpaper settings, so users can
switch images without replacing files or changing the system theme. The source
art is kept in `overlay/usr/share/wallpapers/` and packaged into the next ISO.

The five newest scenes are also available in the website gallery and hero rotation.
Violet Twilight includes a subtle “Poka Machande” inscription on a foreground rock.
See [artwork provenance and prompts](docs/WALLPAPERS.md). Existing ISO artifacts
are unchanged by this source update; rebuild before expecting the new images in a VM.

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

Contributors can start with the [contribution guide](CONTRIBUTING.md) and submit
changes through pull requests. Owner review is the intended merge policy; GitHub
branch protection must be enabled by the repository owner to enforce it.

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

When reporting a hardware problem, run the bundled read-only report instead of
describing the machine by hand. It covers disks and filesystems, PCI and USB
devices, network interfaces, audio, Vulkan, memory and kernel:

```bash
sudo kilimanjaro-hardware-report
```

## Open project decisions

- Approve the provenance and licensing of project artwork and documentation.
- Enable GitHub branch protection for `main`, requiring pull requests and
  code-owner approval. A `CODEOWNERS` file alone does not enforce review; see
  [contribution guidance](CONTRIBUTING.md).
- Decide where to host the website and signed Kilimanjaro package repository.
- Establish release-key custody, rotation, and fingerprint publication.
- Decide whether optional TurboWarp packaging and offline update bundles are in
  scope, and document redistribution requirements before shipping them.
- Decide whether the NVIDIA proprietary driver belongs in the image. Its
  self-signed DKMS module requires Secure Boot to be disabled unless its key is
  enrolled.

See [docs/ROADMAP.md](docs/ROADMAP.md) for implementation status and the next milestones.
