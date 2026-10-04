#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_command grub-mkrescue
require_command mksquashfs
require_command xorriso
require_command mkfs.msdos
require_command mcopy
require_command mmd
require_command sbverify
require_rootfs

# A Calamares package alone does not pull in all tools needed by our modules
# when APT recommendations are disabled. Fail before creating a broken ISO.
for installer_tool in unsquashfs mkfs.ext4 mkfs.fat mkfs.btrfs mkfs.xfs \
  cryptsetup grub-install grub-mkconfig efibootmgr update-initramfs \
  useradd chpasswd; do
  chroot "$ROOTFS_DIR" /usr/bin/env PATH=/usr/sbin:/usr/bin:/sbin:/bin \
    /bin/sh -c 'command -v "$1" >/dev/null' sh "$installer_tool" || \
    die "Required installer tool is missing from the rootfs: $installer_tool"
done

kernel_path=$(find "$ROOTFS_DIR/boot" -maxdepth 1 -type f -name 'vmlinuz-*' -printf '%T@ %p\n' | sort -nr | awk 'NR == 1 { print $2 }')
kernel_version=${kernel_path##*/vmlinuz-}
initrd_path="$ROOTFS_DIR/boot/initrd.img-$kernel_version"

[[ -n "$kernel_path" && -f "$kernel_path" ]] || die 'No kernel image found in the rootfs.'
[[ -n "$initrd_path" && -f "$initrd_path" ]] || die 'No initramfs image found in the rootfs.'

# The newest image in /boot wins, so an unexpected or half-applied package
# upgrade could otherwise ship an older kernel silently. Refuse instead. The
# kernel comes from the stable suite, where the packaged NVIDIA DKMS module
# builds; see the KILIMANJARO_KERNEL_MIN_MAJOR note in config/build.env.
kernel_major=${kernel_version%%.*}
if [[ ! "$kernel_major" =~ ^[0-9]+$ ]] || (( kernel_major < KILIMANJARO_KERNEL_MIN_MAJOR )); then
  die "Selected kernel $kernel_version is older than the required major $KILIMANJARO_KERNEL_MIN_MAJOR. Check that $DEBIAN_SUITE is reachable and that nothing has pinned the kernel to a newer series than the NVIDIA driver supports."
fi
log "Using kernel $kernel_version from $DEBIAN_SUITE"

reset_build_directory "$ISO_STAGING_DIR"
install -d -m 0755 "$ISO_STAGING_DIR/boot/grub" "$ISO_STAGING_DIR/live" "$OUTPUT_DIR"

log 'Creating compressed live filesystem'
mksquashfs "$ROOTFS_DIR" "$ISO_STAGING_DIR/live/filesystem.squashfs" \
  -comp xz \
  -b 1M \
  -noappend \
  -wildcards

cp "$kernel_path" "$ISO_STAGING_DIR/live/vmlinuz"
cp "$initrd_path" "$ISO_STAGING_DIR/live/initrd.img"
cp "$PROJECT_ROOT/overlay/usr/share/wallpapers/Kilimanjaro/contents/images/3840x2160.png" \
  "$ISO_STAGING_DIR/boot/grub/kilimanjaro.png"

# Build the removable-media EFI System Partition with Debian's Microsoft-trusted
# shim and Debian-signed removable GRUB binary. Keep BIOS boot provided by the
# normal grub-mkrescue path below.
signed_grub="$ROOTFS_DIR/usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed"
signed_shim="$ROOTFS_DIR/usr/lib/shim/shimx64.efi.signed"
[[ -r "$signed_grub" && -r "$signed_shim" ]] || \
  die 'Secure Boot is required, but Debian signed shim/GRUB packages are missing.'
sbverify --list "$signed_grub" >/dev/null
sbverify --list "$signed_shim" >/dev/null

secure_efi_dir="$BUILD_DIR/secure-efi"
reset_build_directory "$secure_efi_dir"
install -d -m 0755 "$secure_efi_dir/EFI/BOOT"
cp "$signed_shim" "$secure_efi_dir/EFI/BOOT/BOOTX64.EFI"
cp "$signed_grub" "$secure_efi_dir/EFI/BOOT/GRUBX64.EFI"
install -d -m 0755 "$ISO_STAGING_DIR/EFI/BOOT"
cp "$secure_efi_dir/EFI/BOOT/BOOTX64.EFI" "$ISO_STAGING_DIR/EFI/BOOT/BOOTX64.EFI"
cp "$secure_efi_dir/EFI/BOOT/GRUBX64.EFI" "$ISO_STAGING_DIR/EFI/BOOT/GRUBX64.EFI"
cat > "$secure_efi_dir/grub.cfg" <<'EOF'
search --set=root --file /live/vmlinuz
set prefix=($root)/boot/grub
configfile ($root)/boot/grub/grub.cfg
EOF

efi_image="$BUILD_DIR/kilimanjaro-efi.img"
efi_bytes=$(($(stat -c %s "$secure_efi_dir/EFI/BOOT/BOOTX64.EFI") + \
  $(stat -c %s "$secure_efi_dir/EFI/BOOT/GRUBX64.EFI") + \
  $(stat -c %s "$secure_efi_dir/grub.cfg") + 16384))
efi_blocks=$(( (efi_bytes / 1024 + 55) / 32 * 32 ))
rm -f -- "$efi_image"
mkfs.msdos -C "$efi_image" "$efi_blocks" >/dev/null
mmd -i "$efi_image" ::EFI
mmd -i "$efi_image" ::EFI/BOOT
mcopy -i "$efi_image" "$secure_efi_dir/EFI/BOOT/BOOTX64.EFI" ::EFI/BOOT/
mcopy -i "$efi_image" "$secure_efi_dir/EFI/BOOT/GRUBX64.EFI" ::EFI/BOOT/
mmd -i "$efi_image" ::boot
mmd -i "$efi_image" ::boot/grub
mcopy -i "$efi_image" "$secure_efi_dir/grub.cfg" ::boot/grub/

du -sx --block-size=1 "$ROOTFS_DIR" | cut -f1 > "$ISO_STAGING_DIR/live/filesystem.size"
chroot "$ROOTFS_DIR" dpkg-query -W \
  -f='${Package} ${Version}\n' > "$ISO_STAGING_DIR/live/filesystem.packages"

cat > "$ISO_STAGING_DIR/boot/grub/grub.cfg" <<EOF
set default=0
set timeout=5

insmod all_video
insmod png

if loadfont unicode; then
    set gfxmode=auto
    insmod gfxterm
    terminal_output gfxterm
fi

background_image /boot/grub/kilimanjaro.png
set color_normal=white/black
set color_highlight=black/light-gray

menuentry "$OS_NAME $OS_VERSION_ID Live" {
    linux /live/vmlinuz boot=live components quiet splash live-media-timeout=30 username=$LIVE_USERNAME hostname=$LIVE_HOSTNAME locales=$DEFAULT_LOCALE,$FALLBACK_LOCALE keyboard-layouts=us console=ttyS0,115200n8 console=tty0
    initrd /live/initrd.img
}

menuentry "$OS_NAME $OS_VERSION_ID Live (safe graphics)" {
    linux /live/vmlinuz boot=live components nomodeset live-media-timeout=30 username=$LIVE_USERNAME hostname=$LIVE_HOSTNAME locales=$DEFAULT_LOCALE,$FALLBACK_LOCALE keyboard-layouts=us console=ttyS0,115200n8 console=tty0
    initrd /live/initrd.img
}
EOF

log 'Generating GRUB BIOS files before assembling the signed hybrid ISO'
grub-mkrescue \
  -o "$BUILD_DIR/unsigned-bootstrap.iso" \
  "$ISO_STAGING_DIR" \
  -- \
  -volid "$ISO_LABEL"

# Reuse GRUB's complete BIOS modules, fonts and BIOS El Torito core image, but
# assemble the final hybrid ISO directly so no unsigned GRUB EFI image ships.
grub_boot_tree="$BUILD_DIR/grub-boot-tree"
reset_build_directory "$grub_boot_tree"
xorriso -osirrox on -indev "$BUILD_DIR/unsigned-bootstrap.iso" \
  -extract /boot/grub "$grub_boot_tree" -end >/dev/null
cp -a "$grub_boot_tree/." "$ISO_STAGING_DIR/boot/grub/"
cp "$efi_image" "$ISO_STAGING_DIR/boot/grub/efi.img"

bash "$SCRIPT_DIR/assemble-iso.sh"
