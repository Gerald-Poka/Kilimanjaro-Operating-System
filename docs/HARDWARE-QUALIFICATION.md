# Physical-PC readiness and safe test plan

The target is a directly installable amd64 desktop, not a VM-only product.
VMs are used to test it without putting the owner's existing files at risk.
Physical qualification is deferred until suitable test hardware is available.
No current-PC installation or physical USB write is authorized by this plan.

## Compatibility target, not a certification

The owner wants PCs capable of running Ubuntu 26.04 to be candidates for
Kilimanjaro. Restrict this target to 64-bit Intel/AMD PCs: this ISO does not
support every architecture Ubuntu supports.

This build runs Debian's stable 6.12 LTS kernel rather than being compiled here,
whereas Ubuntu 26.04 ships Linux 7.0. Matching Ubuntu's kernel version does not
match its driver, firmware or userspace baseline, so this stays a compatibility
target rather than a guarantee. The kernel is held at 6.12 deliberately: it is
the newest series any NVIDIA driver in any Debian suite builds against, so
matching Ubuntu's 7.x would cost the proprietary NVIDIA driver entirely. See
"Ubuntu 26.04 is a target, not a guarantee" in `docs/DEVELOPMENT.md` for the
concrete DKMS failures against 7.1.

6.12 is an LTS series, so it receives fixes for longer than a current-release
kernel would. Newer hardware may still need a newer signed kernel, firmware or
drivers. Ubuntu support therefore does not establish Kilimanjaro support.
Evaluate a Debian-maintained hardware-enablement path separately; never mix
Ubuntu packages into Debian or change kernels solely to match a version number.

Sources: [Ubuntu release notes](https://documentation.ubuntu.com/release-notes/26.04/changes-since-previous-interim/)
and [Debian 13 release information](https://www.debian.org/News/2025/20250809).

## Changes included in the rebuilt development ISO

- Explicit Intel/AMD graphics firmware, Intel/SOF audio firmware, common
  Intel/Realtek/Atheros/MediaTek Wi-Fi firmware and Intel/AMD CPU microcode.
- NVIDIA GSP plus legacy graphics firmware, and the proprietary NVIDIA driver
  with `dkms` and kernel headers, so NVIDIA cards get hardware acceleration.
  See the note below for what that still requires.
- Mesa OpenGL/Vulkan drivers, Vulkan diagnostics, `glxinfo`, BlueZ and KDE
  Bluetooth UI.
- Firmware updates over LVFS (`fwupd`), so an in-OS remedy exists for firmware
  faults instead of requiring a vendor ISO.
- Printing (CUPS with network discovery and PDF output) and scanning
  (`sane-utils-simple-scan`).
- Accessibility: Orca screen reader, KMag magnifier and `espeak-ng`.
- On-screen keyboard and IBus input methods for touch and tablet hardware.
- SMB/CIFS and NFS clients, VPN front ends, broadband modem support, and
  guest integration agents for QEMU/KVM, VMware and VirtualBox.
- Explicit USB mass-storage/UAS/xHCI/EHCI and NVMe initramfs modules, alongside
  existing SATA/CD-ROM/live-filesystem support.
- GPL code license/scope packaged in `/usr/share/doc/kilimanjaro/`.
- Read-only `kilimanjaro-hardware-report` diagnostic command. It does not install
  drivers, change firmware, repair partitions, upload reports or prove compatibility.
  It now also captures USB devices, wireless/Bluetooth switches, SMART and NVMe
  health, firmware versions, temperatures, link negotiation, audio devices, GLX
  renderer and recent boot errors. The disk-health sections can expose disk
  serial numbers, so review a saved report before sharing it.

Packages and configured services are not evidence that actual devices work.
NVIDIA driver selection and ASUS ROG controls remain unqualified. Secure Boot is
disabled in the target deployment, so the unenrolled DKMS MOK is not a blocker;
see the Secure Boot note below.

### What shipping the NVIDIA driver now requires

An earlier image shipped `nvidia-settings` with no driver behind it: the
alternatives pointed into an empty `/usr/lib/nvidia/current`, so the control
panel could never work. `nvidia-driver` is now shipped together with
`nvidia-settings`, so the panel finally has a real driver behind it, and
AMD/Intel machines are unaffected and continue to use Mesa.

This is not free of consequences, and they must be qualified on real hardware:

- The driver is non-free, large (it pulls roughly 128 packages, including
  `systemd`) and is built locally by `dkms` at package-install time.
- `dkms` needs headers matching the running kernel. Because the build installs
  with `--no-install-recommends`, those headers are declared explicitly in
  `config/packages/base.list`, and nothing may pin `linux-image-amd64` or
  `linux-headers-amd64` to a different suite than the other. A mismatch breaks
  the module build.
- The kernel is held at the 6.12 LTS series because no NVIDIA driver in any
  Debian suite builds against 7.x. Each kernel bump still triggers a fresh DKMS
  rebuild, and a failed rebuild presents as a black screen. A kernel bump that
  reaches 7.x will break NVIDIA entirely, so treat the kernel series as
  NVIDIA-coupled and re-verify DKMS before raising it.
  Before any unattended deployment, confirm the module builds and that a
  previous kernel stays selectable from the boot menu.
- Secure Boot: the target deployment has Secure Boot disabled in the PC BIOS, so
  no signature is enforced at boot and the DKMS-signed NVIDIA modules load
  without any enrolment step. That is a deliberate deployment choice, not a
  property of this image: Debian signs the kernel, shim and GRUB, but the
  NVIDIA module is signed with a self-signed MOK generated at package-install
  time and is not enrolled. If Secure Boot is ever enabled on a target machine,
  the NVIDIA modules will be rejected until that MOK is enrolled, so treat
  Secure Boot as unsupported while the proprietary driver ships. Do not
  substitute a locally built kernel without solving signing first.

NVIDIA driver selection, DKMS rebuilds across kernel updates, hybrid graphics
and ASUS ROG controls all remain unqualified until tested on physical hardware.

## Repeatable virtual-media checks

`make smoke-test` checks optical BIOS live boot; `make smoke-usb` checks BIOS
with the ISO attached as read-only virtual USB. `make smoke-secureboot-usb`
checks the same virtual USB with Secure Boot firmware and requires the guest
to report Secure Boot enabled plus running graphical target, SDDM and Plasma.
The latter needs enrolled-key OVMF firmware; set `OVMF_CODE` and
`OVMF_VARS_TEMPLATE` to suitable firmware files on other hosts. Every run uses
a disposable copy of the variable store. None of these commands writes a
physical USB or proves installation, rendering quality or physical GPU support.

## A 32 GB flash drive: two different uses

1. **Live boot media:** writing the ISO replaces the selected flash drive's
   contents. Boot it and explore without launching the installer. This can test
   display, audio, networking and input, but not installed-system reliability.
   Live boot is not a guarantee that internal storage is inaccessible; do not
   mount, edit or install onto internal disks during a no-data-change test.
2. **Installed external system:** installing onto an external drive is different
   from flashing an ISO. It requires a separate boot medium and can write a
   bootloader or modify firmware boot entries. A slow USB flash drive is also
   less suitable for sustained OS writes than an external SSD.

Do neither automatically. First confirm the exact device identity, its capacity
and that it contains no needed data; obtain explicit overwrite approval. Never
guess `/dev/sdX` or reuse a device path observed earlier. No raw `dd` instruction
is provided as a substitute for this confirmation.

For an eventual installed-system test, use a spare computer or blank spare SSD,
with a verified backup and recovery media. Disconnect unrelated disks where
practical and have a knowledgeable person inspect the partition/bootloader
summary. Keep the owner's current system unchanged until that test is available.

## Acceptance matrix for each model

Record exact ISO SHA-256, model, firmware mode, kernel, active drivers and results.
"Not tested" is not "passed"; a VM result is not a physical result.

| Check | Evidence required | Current physical status |
|---|---|---|
| Live USB boot | UEFI and applicable BIOS; no initramfs failure | Not tested |
| Secure Boot | Boot with enrolled vendor keys; report enabled | Not tested |
| Installation | Confirmed disposable destination; installer completes | Not tested |
| Installed reboot | ISO removed; correct user and root disk; Plasma usable | Not tested |
| Display/input | Scaling, external monitor, keyboard/touchpad | Not tested |
| Networking | Wi-Fi/Ethernet, reconnect, metered setting | Not tested |
| Audio/camera/Bluetooth | Speaker, mic, recording/call, pairing | Not tested |
| Graphics | Accelerated renderer; supported GPU/driver; hybrid modes | Not tested |
| Printing | Local and network printer discovered, page test | Not tested |
| Scanning | Flatbed sheet test via simple-scan | Not tested |
| Accessibility | Screen reader and magnifier usable | Not tested |
| Touch input | On-screen keyboard and touchscreen input | Not tested |
| Firmware | `fwupdmgr get-devices` lists the device | Not tested |
| Storage health | SMART/NVMe readable; no failing drive | Not tested |
| File server | SMB and NFS share reachable from Dolphin | Not tested |
| Laptop power | Battery, suspend/resume, brightness, thermals | Not tested |
| Updates | Review/update/reboot and device regression checks | Not tested |
| Recovery | Verified personal backup plus tested system restore | Not tested |

Run `kilimanjaro-hardware-report` in the live/installed guest when available, or
`bash scripts/hardware-report.sh` from source. Redirect only to a new report
path if you want a saved file. Review its device/mount information before sharing.
Do not include passwords, keys, account data or hardware serial numbers.

## Release blockers

Retain development labeling until the installation/desktop, recovery, graphics,
release authentication and representative hardware gates are met. Complete
license/provenance review separately. Broad Ubuntu-class support is an objective,
not an advertised guarantee while this matrix is empty.
