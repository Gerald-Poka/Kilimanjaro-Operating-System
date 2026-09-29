# Development readiness review — 30 September 2026

This is a scoped implementation/review record, not a certification, legal
opinion, exhaustive vulnerability audit or permission to install on the owner's PC.
The owner explicitly deferred physical installation and physical USB writes.

## Artifact

`output/kilimanjaro-os-0.1.0-amd64.iso`

SHA-256: `3c6ff34476753d65ad1a70151f8418518b290526da825f64bb41ead6dbfd692c`

The local website download is staged from this artifact. It is a development
ISO with checksums, not a GPG-authenticated public release. No public publishing
or owner release-key creation was performed.

## Changes and findings

- Added canonical GPL-3.0 and scoped original code as GPL-3.0-only. Packaged the
  notices in the OS and website. Upstream authors and file-specific licenses
  remain intact; GPL does not relicense the entire ISO or third-party apps.
- Added explicit Intel/AMD graphics, common Wi-Fi and Intel/SOF audio firmware,
  CPU microcode, Mesa graphics/Vulkan packages and Bluetooth integration.
  Added USB/storage initramfs modules and a read-only hardware report command.
- Fixed stale detached signatures surviving a rebuilt unsigned ISO. Signing
  now requires a full fingerprint, verifies both signatures before publishing
  them, and exports only the public verification key.
- BIOS USB boot failed because the GRUB MBR was passed using an ISOLINUX option.
  Corrected GRUB2 MBR and boot-image patching.
- UEFI USB initially could not find its loader. Added a proper appended GPT EFI
  System Partition instead of marking the EFI image as GPT Basic Data.
  Inspection checks the partition GUID and compares its bytes with the signed
  optical EFI image. Optical and USB boot require separate regression tests.
- ISO inspection now reads the filesystem actually embedded in the ISO rather
  than an unrelated staging tree.

## Evidence and limits

Source validation and six release regression tests passed. The release tests
include real GPG verification and tamper rejection using isolated, disposable
test keys; those keys do not authenticate Gerald or a Kilimanjaro release.

Website browser tests passed 23 tests with one intentional mobile-pointer skip;
the production bundle builds. The ISO's embedded firmware/package baseline,
root ownership, packaged GPL notice and PE signature presence were inspected.
PE signature presence alone does not prove firmware acceptance or ISO authenticity.

Virtual boot checks for this exact artifact passed:

| Virtual media / firmware | Result |
|---|---|
| Optical / BIOS | Graphical target, SDDM and Plasma running |
| USB / BIOS | Graphical target, SDDM and Plasma running |
| USB / UEFI Secure Boot | Secure Boot enabled; graphical target, SDDM and Plasma running |

Logs are under `build/test/optical/`, `build/test/usb/` and
`build/test/secureboot-usb/`. Static inspection also passed after adding the
actual USB EFI partition byte-comparison check. These are service-readiness
checks, not visual rendering, physical hardware or installed-system certification.

Previous offline UEFI installation testing used an older artifact and must not
be treated as full installed-system qualification of this rebuilt ISO.

CodeRabbit could not run because this workspace is not a Git repository; no
external automated code review was performed. Manual inspection and regression
checks do not establish that every issue has been found.

## Open release gates

- Physical live boot, installer destination safety, installed desktop/reboot,
  BIOS installation, encryption/dual boot, update/recovery and hardware matrix.
- NVIDIA driver/MOK enrollment, hybrid graphics and ASUS ROG controls on actual
  models. Ubuntu 26.04 compatibility is an amd64 goal, not a blanket guarantee.
- Trusted-LAN KDE Connect firewall integration: keep UFW enabled; do not open
  discovery/service ports globally just to make pairing work. Review a scoped
  exception against [KDE Connect's documentation](https://userbase.kde.org/KDEConnect).
- Personal release-signing key creation/custody, fingerprint distribution and
  authenticated release publication after testing.
- Artwork/documentation provenance, third-party redistribution/source obligations,
  privacy/legal review and final release claims. Preserve development notices.
- Full translated-interface validation and remaining roadmap acceptance tests.

See [the physical qualification plan](HARDWARE-QUALIFICATION.md). No physical
device has been qualified by virtual-media success.
