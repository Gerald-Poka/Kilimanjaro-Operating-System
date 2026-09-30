# Development readiness review — 30 September 2026

This is a scoped implementation/review record, not a certification, legal
opinion, exhaustive vulnerability audit or permission to install on the owner's PC.
The owner explicitly deferred physical installation and physical USB writes.

## Artifact

`output/kilimanjaro-os-0.1.0-amd64.iso`

SHA-256: `8ddb15abc7570273bfec077da6cacf1c67249803d2d747072e6e28cf9d4a9589`

The local website download is staged from this artifact. It is a development
ISO with checksums, not a GPG-authenticated public release. No public publishing
or owner release-key creation was performed.

## Changes and findings

- Versioned `kilimanjaro-base` and `kilimanjaro-desktop` packages are now
  installed in the ISO and registered with dpkg. Signed project repository
  snapshot generation and scoped client files are implemented. Actual local
  signed APT installation/upgrade and tamper/expiry rejection passed; see
  [APT integration evidence](APT-TEST-RESULTS.md). Public hosting and the
  owner's trusted archive key remain pending by explicit choice.

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

Website browser tests passed 27 tests with one intentional mobile-pointer skip;
the production bundle builds. The ISO's embedded firmware/package baseline,
root ownership, packaged GPL notice and PE signature presence were inspected.
PE signature presence alone does not prove firmware acceptance or ISO authenticity.

Virtual boot checks for this exact artifact passed:

| Virtual media / firmware | Result |
|---|---|
| Optical / BIOS | Graphical target, SDDM and Plasma running |
| USB / BIOS | Graphical target, SDDM and Plasma running |
| USB / UEFI Secure Boot (software emulation) | Secure Boot enabled; graphical target, SDDM and Plasma running |

Passed logs are under `build/test/optical/`, `build/test/usb/` and
`build/test/secureboot-tcg-final/`. Static inspection also passed after adding the
actual USB EFI partition byte-comparison check. These are service-readiness
checks, not visual rendering, physical hardware or installed-system certification.

The current KVM Secure Boot rerun failed at firmware startup with
`Unsupported image`; preserve that result in `build/test/secureboot-usb/`.
The clean software-emulated run uses `build/test/secureboot-tcg-final/` and
`SMOKE_ACCEL=tcg SMOKE_MEMORY=4096 SMOKE_CPUS=4 SMOKE_TIMEOUT=600`.
An earlier guest-confirmed run ended with a wrapper error after its script was
edited while running; the unchanged-script repeat exited successfully.
A software-emulated pass does not resolve
the KVM failure or qualify physical firmware. Investigate before broader claims.

Previous offline UEFI installation testing used an older artifact and must not
be treated as full installed-system qualification of this rebuilt ISO.

During the initial readiness review, CodeRabbit could not run because the
workspace was not yet a Git repository. Git has since been initialized and
source published; no external automated review of these APT changes is claimed.
Manual inspection and regression
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
