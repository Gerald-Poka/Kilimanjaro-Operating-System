# Physical-PC readiness and safe test plan

The target is a directly installable amd64 desktop, not a VM-only product.
VMs are used to test it without putting the owner's existing files at risk.
Physical qualification is deferred until suitable test hardware is available.
No current-PC installation or physical USB write is authorized by this plan.

## Compatibility target, not a certification

The owner wants PCs capable of running Ubuntu 26.04 to be candidates for
Kilimanjaro. Restrict this target to 64-bit Intel/AMD PCs: this ISO does not
support every architecture Ubuntu supports.

Ubuntu 26.04 ships Linux 7.0; this Debian 13 build uses the Debian 6.12 kernel
series. Newer hardware may need a newer signed kernel, firmware or drivers.
Ubuntu support therefore does not establish Kilimanjaro support. Evaluate a
Debian-maintained backports hardware-enablement path separately; never mix Ubuntu
packages into Debian or change kernels solely to match a version number.

Sources: [Ubuntu release notes](https://documentation.ubuntu.com/release-notes/26.04/changes-since-previous-interim/)
and [Debian 13 release information](https://www.debian.org/News/2025/20250809).

## Changes included in the rebuilt development ISO

- Explicit Intel/AMD graphics firmware, Intel/SOF audio firmware, common
  Intel/Realtek/Atheros/MediaTek Wi-Fi firmware and Intel/AMD CPU microcode.
- Mesa OpenGL/Vulkan drivers, Vulkan diagnostics, BlueZ and KDE Bluetooth UI.
- Explicit USB mass-storage/UAS/xHCI/EHCI and NVMe initramfs modules, alongside
  existing SATA/CD-ROM/live-filesystem support.
- GPL code license/scope packaged in `/usr/share/doc/kilimanjaro/`.
- Read-only `kilimanjaro-hardware-report` diagnostic command. It does not install
  drivers, change firmware, repair partitions, upload reports or prove compatibility.

Packages and configured services are not evidence that actual devices work.
NVIDIA driver selection/MOK enrollment and ASUS ROG controls remain unqualified.

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
