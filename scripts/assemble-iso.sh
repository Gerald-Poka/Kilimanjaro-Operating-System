#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/common.sh"
require_root
require_rootfs
for program in xorriso mcopy sbverify; do require_command "$program"; done
for artifact in live/filesystem.squashfs live/vmlinuz live/initrd.img \
  boot/grub/i386-pc/eltorito.img boot/grub/efi.img boot/grub/grub.cfg; do
  [[ -f "$ISO_STAGING_DIR/$artifact" ]] || die "Missing staged boot artifact: $artifact"
done
signed_grub="$ROOTFS_DIR/usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed"
signed_shim="$ROOTFS_DIR/usr/lib/shim/shimx64.efi.signed"
log 'Assembling GRUB2 hybrid boot records from the existing staged filesystem'
secure_iso="$ISO_PATH.secureboot.tmp"
xorriso -as mkisofs \
  -R -r -J -joliet-long -l -cache-inodes -iso-level 3 \
  --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
  --protective-msdos-label --mbr-force-bootable \
  -partition_offset 16 \
  -V "$ISO_LABEL" \
  -o "$secure_iso" \
  -b boot/grub/i386-pc/eltorito.img \
  -c boot/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e boot/grub/efi.img -no-emul-boot \
  -append_partition 2 0xef "$ISO_STAGING_DIR/boot/grub/efi.img" \
  -appended_part_as_gpt \
  "$ISO_STAGING_DIR"
mv -f -- "$secure_iso" "$ISO_PATH"

log 'Checking signed UEFI boot chain in the final ISO'
xorriso -indev "$ISO_PATH" -report_el_torito as_mkisofs 2>&1 | \
  grep -Eq 'boot/grub/efi\.img|efi\.img' || die 'Final ISO has no UEFI El Torito image.'
xorriso -osirrox on -indev "$ISO_PATH" \
  -extract /boot/grub/efi.img "$BUILD_DIR/verified-efi.img" \
  -end >/dev/null
mcopy -i "$BUILD_DIR/verified-efi.img" ::EFI/BOOT/BOOTX64.EFI "$BUILD_DIR/verified-shim.efi"
mcopy -i "$BUILD_DIR/verified-efi.img" ::EFI/BOOT/GRUBX64.EFI "$BUILD_DIR/verified-grub.efi"
cmp -s "$BUILD_DIR/verified-shim.efi" "$signed_shim" || die 'ISO shim differs from Debian signed shim.'
cmp -s "$BUILD_DIR/verified-grub.efi" "$signed_grub" || die 'ISO GRUB differs from Debian signed removable GRUB.'
sbverify --list "$BUILD_DIR/verified-shim.efi" >/dev/null
sbverify --list "$BUILD_DIR/verified-grub.efi" >/dev/null

log 'ISO image created.'
