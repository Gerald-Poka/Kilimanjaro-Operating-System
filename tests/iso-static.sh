#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../config/build.env
source "$ROOT_DIR/config/build.env"

iso_path="$ROOT_DIR/output/$ISO_BASENAME"
checksum_path="$ROOT_DIR/output/SHA256SUMS"
report_dir="$ROOT_DIR/output/reports"
report_path="$report_dir/iso-boot-report.txt"

command -v xorriso >/dev/null 2>&1 || {
  printf 'FAIL: xorriso is required for ISO inspection\n' >&2
  exit 1
}
[[ -f "$iso_path" ]] || {
  printf 'FAIL: ISO not found: %s\n' "$iso_path" >&2
  exit 1
}
[[ -f "$checksum_path" ]] || {
  printf 'FAIL: checksum file not found: %s\n' "$checksum_path" >&2
  exit 1
}

(cd "$ROOT_DIR/output" && sha256sum -c SHA256SUMS)

install -d -m 0755 "$report_dir"
xorriso -indev "$iso_path" -report_el_torito plain >"$report_path" 2>&1
xorriso -indev "$iso_path" -report_system_area plain > "$report_dir/iso-system-area.txt" 2>&1
grep -q 'grub2-mbr' "$report_dir/iso-system-area.txt" || {
  printf 'FAIL: GRUB2 hybrid USB MBR address patching is missing\n' >&2
  exit 1
}
grep -Eq 'GPT type GUID +: +2 +28732ac11ff8d211ba4b00a0c93ec93b' "$report_dir/iso-system-area.txt" || {
  printf 'FAIL: appended USB EFI System Partition is missing\n' >&2
  exit 1
}
grep -q 'grub2-boot-info' "$report_path" || {
  printf 'FAIL: GRUB2 BIOS boot-image address patching is missing\n' >&2
  exit 1
}

grep -Eq 'El Torito boot img : +1 +BIOS +y' "$report_path" || {
  printf 'FAIL: no bootable BIOS entry was found\n' >&2
  exit 1
}
grep -Eq 'El Torito boot img : +2 +UEFI +y' "$report_path" || {
  printf 'FAIL: no bootable UEFI entry was found\n' >&2
  exit 1
}

secure_efi="$report_dir/verified-efi.img"
xorriso -osirrox on -indev "$iso_path" \
  -extract /live/filesystem.packages "$report_dir/filesystem.packages" -end >/dev/null
xorriso -osirrox on -indev "$iso_path" \
  -extract /boot/grub/efi.img "$secure_efi" -end >/dev/null
# Read only the ISO file, never a physical device. USB and optical EFI images
# must contain exactly the same signed boot chain.
read -r esp_start esp_size < <(awk '/GPT start and size/ && $6 == 2 {print $7, $8}' "$report_dir/iso-system-area.txt")
[[ "$esp_start" =~ ^[0-9]+$ && "$esp_size" =~ ^[0-9]+$ ]] || exit 1
dd if="$iso_path" of="$report_dir/verified-usb-efi.img" bs=512 skip="$esp_start" count="$esp_size" status=none
cmp "$secure_efi" "$report_dir/verified-usb-efi.img"
mcopy -i "$secure_efi" ::EFI/BOOT/BOOTX64.EFI "$report_dir/shimx64.efi"
mcopy -i "$secure_efi" ::EFI/BOOT/GRUBX64.EFI "$report_dir/grubx64.efi"
sbverify --list "$report_dir/shimx64.efi" >/dev/null
sbverify --list "$report_dir/grubx64.efi" >/dev/null
xorriso -osirrox on -indev "$iso_path" \
  -extract /live/vmlinuz "$report_dir/vmlinuz" -end >/dev/null
sbverify --list "$report_dir/vmlinuz" >/dev/null

# The live kernel also has to be present in the filesystem copied by Calamares.
# Inspect the filesystem actually embedded in this ISO, not a potentially stale
# build/iso tree left over from a different repack.
inspection_dir=$(mktemp -d "$report_dir/.iso-inspect-XXXXXX")
cleanup() {
  rm -f -- "$inspection_dir/filesystem.squashfs"
  rmdir -- "$inspection_dir" 2>/dev/null || true
}
trap cleanup EXIT
staged_root="$inspection_dir/filesystem.squashfs"
xorriso -osirrox on -indev "$iso_path" \
  -extract /live/filesystem.squashfs "$staged_root" -end >/dev/null
unsquashfs -ll "$staged_root" boot > "$report_dir/installed-kernel-files.txt"
grep -Eq 'squashfs-root/boot/vmlinuz-[^ ]+' "$report_dir/installed-kernel-files.txt" || {
  printf 'FAIL: installer filesystem is missing its kernel\n' >&2
  exit 1
}
unsquashfs -ll "$staged_root" usr/bin/mount > "$report_dir/root-ownership.txt"
grep -Eq 'root/root.*squashfs-root/usr/bin/mount$' "$report_dir/root-ownership.txt" || {
  printf 'FAIL: mount is not root-owned in the installer filesystem\n' >&2
  exit 1
}
unsquashfs -ll "$staged_root" var/cache/cracklib > "$report_dir/password-dictionary.txt"
grep -Eq 'squashfs-root/var/cache/cracklib/cracklib_dict.pwd$' "$report_dir/password-dictionary.txt" || {
  printf 'FAIL: installer password dictionary is missing\n' >&2
  exit 1
}
unsquashfs -cat "$staged_root" usr/share/doc/kilimanjaro/LICENSE \
  > "$report_dir/kilimanjaro-LICENSE.txt"
cmp -s "$report_dir/kilimanjaro-LICENSE.txt" "$ROOT_DIR/LICENSE" || {
  printf 'FAIL: packaged project license differs from repository license\n' >&2
  exit 1
}
for package in firmware-intel-graphics firmware-amd-graphics firmware-intel-sound \
  firmware-sof-signed firmware-atheros firmware-mediatek firmware-nvidia-gsp \
  intel-microcode amd64-microcode bluez bluedevil mesa-vulkan-drivers vulkan-tools \
  fwupd smartmontools lm-sensors ethtool; do
  grep -Eq "^$package " "$report_dir/filesystem.packages" || {
    printf 'FAIL: physical-PC baseline package missing: %s\n' "$package" >&2
    exit 1
  }
done

# Capabilities the documented product features depend on. A release whose ISO
# cannot print, cannot list software, or cannot spellcheck is not releasable.
for package in plasma-discover packagekit \
  cups cups-client cups-browsed foomatic-db-compressed-ppds sane-utils \
  orca kmag espeak-ng ibus plasma-nano libpam-kwallet-common mesa-utils; do
  grep -Eq "^$package " "$report_dir/filesystem.packages" || {
    printf 'FAIL: documented desktop capability missing: %s\n' "$package" >&2
    exit 1
  }
done

for package in hunspell-sw hunspell-en-gb p7zip-full; do
  grep -Eq "^$package " "$report_dir/filesystem.packages" || {
    printf 'FAIL: documented application missing: %s\n' "$package" >&2
    exit 1
  }
done

# Deliberately absent. These must never reappear in a published image.
for package in nvidia-settings clamav clamav-daemon ttf-mscorefonts-installer; do
  if grep -Eq "^$package " "$report_dir/filesystem.packages"; then
    printf 'FAIL: package removed by policy is present: %s\n' "$package" >&2
    exit 1
  fi
done

for package in e2fsprogs btrfs-progs xfsprogs cracklib-runtime wamerican \
  efibootmgr grub-pc-bin cryptsetup-initramfs iproute2 unattended-upgrades; do
  grep -Eq "^$package " "$report_dir/filesystem.packages" || {
    printf 'FAIL: required installer utility package missing: %s\n' "$package" >&2
    exit 1
  }
done
for package in kilimanjaro-base kilimanjaro-desktop; do
  grep -Fxq "$package $KILIMANJARO_PACKAGE_VERSION" "$report_dir/filesystem.packages" || {
    printf 'FAIL: versioned project package missing: %s\n' "$package" >&2
    exit 1
  }
done

# The kernel must be the 6.x series the packaged NVIDIA DKMS module builds
# against. Its ABI package name carries the version, so this also catches an
# image that picked up a 7.x kernel that has no working proprietary driver.
if ! grep -Eq '^linux-image-6\.[0-9]+\.[0-9]+.*-amd64 ' "$report_dir/filesystem.packages"; then
  printf 'FAIL: no 6.x kernel package in the live system manifest\n' >&2
  exit 1
fi
if grep -Eq '^linux-image-(7|8)\.' "$report_dir/filesystem.packages"; then
  printf 'FAIL: 7.x-or-newer kernel present; no packaged NVIDIA driver builds against it\n' >&2
  exit 1
fi

# Headers must match the kernel series or the NVIDIA module cannot build.
if ! grep -Eq '^linux-headers-6\.[0-9]+' "$report_dir/filesystem.packages"; then
  printf 'FAIL: no matching 6.x kernel headers; DKMS/NVIDIA builds would fail\n' >&2
  exit 1
fi

grep -Eq '^shim-signed ' "$report_dir/filesystem.packages" || {
  printf 'FAIL: shim-signed is missing from the live system package manifest\n' >&2
  exit 1
}
grep -Eq '^grub-efi-amd64-signed ' "$report_dir/filesystem.packages" || {
  printf 'FAIL: signed GRUB is missing from the live system package manifest\n' >&2
  exit 1
}

printf 'PASS: checksum verified\n'
printf 'PASS: bootable BIOS entry present\n'
printf 'PASS: bootable UEFI entry present\n'
printf 'PASS: PE signatures present on shim, GRUB and kernel (firmware trust requires boot testing)\n'
printf 'PASS: root-owned installed filesystem and packaged GPL license verified\n'
printf 'PASS: explicit physical-PC firmware/graphics package baseline present\n'
printf 'PASS: 6.x kernel and matching headers present, no 7.x kernel\n'
printf 'PASS: documented desktop capabilities present (Discover APT, printing, scanning, a11y, IME)\n'
printf 'PASS: removed-by-policy packages absent from the image\n'
printf 'Report: %s\n' "$report_path"
