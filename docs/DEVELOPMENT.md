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
