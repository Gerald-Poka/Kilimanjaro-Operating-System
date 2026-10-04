# Kilimanjaro OS development workflow

The source tree stays on the host. Debian-specific build tools run in a privileged Podman or Docker container, while QEMU runs on the host for faster graphics and easier hardware emulation.

## One-time setup

The host needs Podman (or Docker) and QEMU. Build the toolchain container and confirm the source tree first:

```bash
make container-image
make validate
```

Use Docker by appending `CONTAINER_ENGINE=docker` to container targets.

On this workstation use `DOCKER_CONTEXT=default make container-repack CONTAINER_ENGINE=docker`.
The Docker Desktop daemon cannot resolve this host's external-drive project mount.
The root filesystem and ISO staging live in the `kilimanjaro-build` named volume,
mounted at `/workspace/build`, to preserve root ownership and setuid permissions.
Do not substitute the old host `build/rootfs` bind mount: it can produce an
unbootable image. Final ISO and checksums are exported into the host `output/`.

## Choose the shortest safe rebuild

For boot-record-only changes after a successful complete build:

```bash
make container-boot-repack
```

This reuses the existing staged SquashFS, kernel, initramfs and EFI files. Do
not use it for package, overlay, firmware or kernel changes; use the normal
repack/update paths below. `scripts/assemble-iso.sh` is shared by full builds
and this boot-only path, so GRUB2 MBR/boot-image address patching is consistent.
Run `make smoke-usb` as well as optical and Secure Boot tests before release.
The USB smoke test uses a read-only virtual device, not a physical flash drive.

After editing files under `overlay/`, Firefox policy, systemd services, localization, or branding:

```bash
make container-repack
```

After changing a package list under `config/packages/`:

```bash
make container-update
```

Incremental targets assume `build/rootfs` is not older than the last ISO. If
the two have drifted, a repack or update will silently drop whatever the older
rootfs never installed. `make test` re-reads the finished ISO and fails on any
missing package, so run it after every rebuild rather than trusting the
incremental path. When in doubt use a clean `make container-iso`.

`make validate` asserts the capabilities the documentation promises (Discover's
APT backend, printing, scanning, accessibility, input methods, spellcheck,
firmware updates) and also asserts that deliberately removed packages stay
removed, so a capability cannot quietly disappear from a list. Adding a
package to an image list needs no approval; removing one that a listed check
depends on does.

To activate the project APT archive channel, set `KILIMANJARO_APT_REPO_URL`,
`KILIMANJARO_APT_REPO_FINGERPRINT` and `KILIMANJARO_APT_REPO_KEY` together in
`config/build.env`. Leave them empty to ship without a channel. Never commit a
private key; `config/build.env` holds a path to a public key only. See
[APT update implementation and activation](APT-UPDATES.md).

After changing optional manifests under
`overlay/usr/share/kilimanjaro/profiles/`, verify all profiles in the disposable
builder container:

```bash
make container-profile-check
```

After changing the Debian suite, architecture, bootstrap logic, or when a clean build must be proven:

```bash
make container-clean
make container-iso
```

`container-repack` reuses the existing root filesystem and is the normal edit-test loop. Its overlay manifest also removes files that you deleted from `overlay/`, preventing stale customizations from surviving a rebuild. The full build downloads and installs the entire operating system again.

## Run all automated checks

```bash
make test
```

The test stack has three layers:

1. Source validation checks shell syntax, policy JSON, manifests, and required files.
2. Static ISO validation verifies the SHA-256 digest and bootable BIOS/UEFI catalog entries.
3. The offline QEMU smoke test boots the live filesystem with no network device and requires SDDM to start for the selected graphical target.

The smoke-test log is written to `build/test/smoke-boot.log`; the static ISO boot report is written to `output/reports/iso-boot-report.txt`.

On a host without KVM access the smoke test uses software emulation and can take several minutes. Its default timeout is 300 seconds. Override it when needed:

```bash
SMOKE_TIMEOUT=300 make smoke-test
```

## Package manifests and the four pillars

Manifests live in `config/packages/` and `scripts/02-packages.sh` loads them by
glob, excluding `optional.list` (which only documents deliberate exclusions).
Adding a pillar is therefore a matter of dropping in a new `.list` file; nothing
needs registering in the script.

| Manifest | Pillar |
| --- | --- |
| `base.list` | kernel, firmware, networking, storage, diagnostics |
| `desktop.list` | KDE Plasma session, settings, accessibility, printing |
| `apps.list` | everyday applications and archives |
| `development.list` | programming toolchain |
| `creator.list` | content creation |
| `gaming.list` | Steam, Wine, performance overlay, NVIDIA driver |

Three build-level requirements are easy to break and are worth understanding
before changing any of this:

- **i386 multiarch.** `steam` and `wine32` are i386 binaries in Debian 13; on an
  amd64-only system `steam` has no installation candidate at all. The package
  stage runs `dpkg --add-architecture i386` before refreshing the indexes.
- **`linux-headers-amd64` must be declared explicitly.** The build uses
  `--no-install-recommends`, which omits the headers that `dkms` needs, so the
  NVIDIA module would never build. Kernel and headers must resolve from the same
  suite; anything that pins either above stable risks pairing mismatched series
  and breaking every DKMS build.
- **Package names are suite-specific.** Debian 13 renamed or dropped a number of
  packages this project previously referenced, including `kwallet-pam`
  (`libpam-kwallet-common`), `partitioneditor` (`partitionmanager`), `ksysguard`
  (`plasma-systemmonitor`), `kio-gvfs` (`kio-extras`), `dnsutils`
  (`bind9-dnsutils`), `firmware-nvidia-nonfree` (`firmware-nvidia-gsp` and
  `firmware-nvidia-graphics`), and `plasma-discover-backend-aptkde`, which no
  longer exists because Discover handles APT itself. `virtualbox-guest-x11` and
  `kde-plasma-addons` are gone from trixie entirely. `make validate` only checks
  that names are declared, not that apt can resolve them, so run
  `make container-package-check` after touching any manifest. An unresolvable
  name aborts the whole install.

## The kernel comes from the stable suite

The image does not compile a kernel. It installs Debian's `linux-image-amd64`
from `$DEBIAN_SUITE` (trixie), currently 6.12.x, together with the matching
headers.

This is deliberate, and it is the reason the image ships a working proprietary
NVIDIA driver. **6.12 is the newest kernel series that any NVIDIA driver in any
Debian suite builds against.** Debian ships `nvidia-driver` 550.163.01 in stable,
`trixie-backports` and sid alike; that driver predates Linux 7.x by roughly two
years and fails to compile against it. The concrete breakages, all confirmed by
building DKMS against `linux-headers-7.1.13+deb13-amd64`:

- `vm_area_struct::__vm_flags` was removed, and `vm_flags` is now `const`
- `in_irq()` was removed in favour of `in_interrupt()`
- `dma_map_ops::map_resource` was removed while the `dma_map_resource()`
  wrapper survived, so NVIDIA's own conftest reports a false positive
- `nvidia-drm.ko` additionally fails on the removed `DRM_DEBUG`/`DRM_ERROR`/
  `DRM_INFO` printk family, the removed `.state` member on DRM atomic state
  structs, a changed `drm_mode_create_dumb`, and DMA-fence API changes

The core driver can be patched through the first three items, but
`nvidia-drm.ko` needs substantially more, and doing so would mean carrying a
permanent private patch against proprietary source, reapplied on every
`nvidia-dkms` update. sid is not an escape hatch: sid itself runs a 7.2 kernel
and still carries the same unbuildable 550.163.01. Shipping 7.x would therefore
have meant either shipping nouveau with no NVIDIA acceleration or maintaining
that fork, so the kernel stays on 6.12.

Two files in the image make the suite policy work, and both are intentionally
kept in the rootfs so installed systems inherit the same narrow policy:

- `/etc/apt/preferences.d/50-kilimanjaro-backports` pins the stable suites at
  500 and all of backports at 100. Nothing is pinned above stable, so the kernel
  and headers both resolve from stable and no backported package is ever
  selected automatically.
- `/etc/apt/apt.conf.d/99-kilimanjaro-default-release` sets
  `APT::Default-Release` to the stable suite.

Backports remains reachable on purpose so users can opt into individual
packages, for example `sudo apt install -t trixie-backports gamescope`.

To confirm the wiring before building:

```bash
apt-cache policy linux-image-amd64 linux-headers-amd64
# both candidates must be the stable 6.12 series
```

`KILIMANJARO_KERNEL_MIN_MAJOR` in `config/build.env` is the floor, and
`scripts/04-image.sh` refuses to assemble an ISO whose newest `/boot/vmlinuz-*`
is older than it. Note that `scripts/04-image.sh` picks the kernel by
modification time, so it takes whatever is newest rather than a hardcoded
version. Do not add `sid` or `unstable` as a kernel source: it pulls an unstable
userspace, not just a kernel. Do not replace this with a self-compiled kernel
without also solving Secure Boot signing, since a locally built kernel is not
signed by Debian and the current chain will reject it.

## Open the graphical VM

Legacy BIOS:

```bash
make vm
```

UEFI:

```bash
make vm-uefi
```

Resource overrides can be supplied without modifying the scripts:

```bash
VM_MEMORY=6144 VM_CPUS=6 make vm-uefi
```

Secure Boot with enrolled Microsoft keys (the default paths match this Nobara host):

```bash
make vm-secureboot
```

If host QEMU/KVM crashes with secure firmware, use `VM_ACCEL=tcg make vm-secureboot`.
Other hosts may need `OVMF_CODE` and `OVMF_VARS_TEMPLATE` pointing to Secure Boot
firmware and a variable template with enrolled Microsoft keys. Secure-capable
firmware alone does not prove that Secure Boot is enabled: check `mokutil --sb-state`
inside the guest.

To inspect the exact QEMU invocation without opening a window:

```bash
VM_DRY_RUN=1 make vm-uefi
```

The live session is disposable. Files created inside it disappear after shutdown.
Each firmware mode also has a persistent 32 GiB installer-test disk at
`build/vm/<firmware>/disk.img`; an existing disk is never recreated by the launcher.
Only this virtual disk is attached, not host disks. Source changes belong in
`overlay/`, package manifests, or build scripts and must be rebuilt into the ISO.

After a successful install, shut down that VM and boot its disk without the ISO:

```bash
VM_BOOT=disk make vm-secureboot
```

## Builder shell

For package inspection or debugging inside the Debian toolchain environment:

```bash
make container-shell
```

The repository is mounted at `/workspace`. The container is disposable; source
and `output/` persist in the project directory, while `/workspace/build` persists
in the named build volume. Back up both source and volume if preserving build state.

## Suggested edit-test loop

```text
edit source or overlay
        |
        +-- package list changed? ---- yes --> make container-update
        |                                  \
        +-- no --> make container-repack ----+--> make test --> make vm
```

Before publishing any image, perform a clean container build and repeat the physical hardware matrix. A successful VM test is necessary but does not prove Wi-Fi, graphics, suspend, modem, printer, or firmware compatibility on real computers.
