#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_command chroot
require_command comm
require_command rsync
require_rootfs

overlay_manifest="$BUILD_DIR/overlay-manifest.txt"
overlay_manifest_next="$BUILD_DIR/overlay-manifest.next"

cleanup() {
  unmount_chroot_filesystems
  rm -f -- "$overlay_manifest_next"
}
trap cleanup EXIT INT TERM

# Register custom tools/artwork with dpkg so future signed project repositories
# can update them. Build in a fresh directory; never silently reuse old packages.
project_packages=$(mktemp -d "$BUILD_DIR/project-packages-XXXXXX")
python3 "$SCRIPT_DIR/build-project-packages.py" \
  --version "$KILIMANJARO_PACKAGE_VERSION" --output "$project_packages"
cp "$project_packages"/*.deb "$ROOTFS_DIR/tmp/"
if ! in_chroot apt-get --simulate --no-install-recommends install \
  "/tmp/kilimanjaro-base_${KILIMANJARO_PACKAGE_VERSION}_all.deb" \
  "/tmp/kilimanjaro-desktop_${KILIMANJARO_PACKAGE_VERSION}_all.deb" \
  > "$project_packages/dependency-plan.txt"; then
  die 'Project package dependency resolution failed; run the package-update stage first.'
fi
if awk '/^Inst / && $2 !~ /^kilimanjaro-/ {missing=1} END {exit !missing}' \
  "$project_packages/dependency-plan.txt"; then
  die 'New Debian dependencies are needed; run container-update rather than an offline repack.'
fi

log 'Applying the Kilimanjaro configuration overlay'
(cd "$PROJECT_ROOT/overlay" && find . \( -type f -o -type l \) -printf '%P\n' | sort) \
  > "$overlay_manifest_next"

# Remove files that were managed by an earlier overlay but were deleted in source.
if [[ -f "$overlay_manifest" ]]; then
  while IFS= read -r relative_path; do
    [[ -n "$relative_path" ]] || continue
    [[ "$relative_path" != /* && "$relative_path" != *'..'* ]] || \
      die "Unsafe path in overlay manifest: $relative_path"
    rm -f -- "$ROOTFS_DIR/$relative_path"
  done < <(comm -23 "$overlay_manifest" "$overlay_manifest_next")
fi

rsync -aHAX --chown=0:0 "$PROJECT_ROOT/overlay/" "$ROOTFS_DIR/"
mv -f -- "$overlay_manifest_next" "$overlay_manifest"

install -D -m 0644 "$PROJECT_ROOT/LICENSE" "$ROOTFS_DIR/usr/share/doc/kilimanjaro/LICENSE"
install -D -m 0644 "$PROJECT_ROOT/LICENSING.md" "$ROOTFS_DIR/usr/share/doc/kilimanjaro/LICENSING.md"
install -D -m 0755 "$PROJECT_ROOT/scripts/hardware-report.sh" "$ROOTFS_DIR/usr/bin/kilimanjaro-hardware-report"

install -d -m 0755 "$ROOTFS_DIR/usr/lib"
cat > "$ROOTFS_DIR/usr/lib/os-release" <<EOF
NAME="$OS_NAME"
VERSION="$OS_VERSION_ID ($OS_VERSION_CODENAME)"
ID=$OS_ID
ID_LIKE=debian
PRETTY_NAME="$OS_NAME $OS_VERSION_ID (created by Gerald Ndyamukama)"
LOGO=kilimanjaro-logo
ANSI_COLOR="0;33"
VERSION_ID="$OS_VERSION_ID"
VERSION_CODENAME=$OS_VERSION_CODENAME
HOME_URL="https://kilimanjaro-os.org/"
SUPPORT_URL="https://kilimanjaro-os.org/support"
BUG_REPORT_URL="https://kilimanjaro-os.org/issues"
EOF
ln -sfn ../usr/lib/os-release "$ROOTFS_DIR/etc/os-release"

printf '%s\n' "$LIVE_HOSTNAME" > "$ROOTFS_DIR/etc/hostname"
cat > "$ROOTFS_DIR/etc/hosts" <<EOF
127.0.0.1 localhost
127.0.1.1 $LIVE_HOSTNAME
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Ensure the live initramfs can access the ISO9660 CD-ROM and compressed root
# filesystem even when built in a container without matching host hardware.
cat > "$ROOTFS_DIR/etc/initramfs-tools/modules" <<'EOF'
ahci
ata_piix
libahci
libata
sr_mod
cdrom
isofs
squashfs
# Physical USB live media and common installed storage controllers.
usb_storage
uas
xhci_hcd
xhci_pci
ehci_hcd
ehci_pci
sd_mod
nvme
EOF

cat > "$ROOTFS_DIR/etc/locale.gen" <<EOF
$DEFAULT_LOCALE UTF-8
$FALLBACK_LOCALE UTF-8
EOF

chmod 0755 \
  "$ROOTFS_DIR/usr/lib/live/config/0090-kilimanjaro-session" \
  "$ROOTFS_DIR/opt/kilimanjaro/bin/kilimanjaro-firstboot" \
  "$ROOTFS_DIR/opt/kilimanjaro/bin/kilimanjaro-netmeter" \
  "$ROOTFS_DIR/opt/kilimanjaro/bin/kilimanjaro-network-monitor" \
  "$ROOTFS_DIR/opt/kilimanjaro/bin/kilimanjaro-software" \
  "$ROOTFS_DIR/opt/kilimanjaro/welcome/kilimanjaro_welcome.py" \
  "$ROOTFS_DIR/usr/bin/kilimanjaro-welcome"

sed -i 's/^ENABLED=.*/ENABLED=yes/' "$ROOTFS_DIR/etc/ufw/ufw.conf"

mount_chroot_filesystems
in_chroot dpkg --force-confold -i \
  "/tmp/kilimanjaro-base_${KILIMANJARO_PACKAGE_VERSION}_all.deb" \
  "/tmp/kilimanjaro-desktop_${KILIMANJARO_PACKAGE_VERSION}_all.deb"
rm -f -- "$ROOTFS_DIR/tmp/kilimanjaro-base_${KILIMANJARO_PACKAGE_VERSION}_all.deb" \
  "$ROOTFS_DIR/tmp/kilimanjaro-desktop_${KILIMANJARO_PACKAGE_VERSION}_all.deb"
in_chroot locale-gen
in_chroot update-initramfs -u -k all
in_chroot update-locale \
  "LANG=$DEFAULT_LOCALE" \
  "LANGUAGE=sw:en_GB:en"
in_chroot ln -sfn "/usr/share/zoneinfo/$DEFAULT_TIMEZONE" /etc/localtime
printf '%s\n' "$DEFAULT_TIMEZONE" > "$ROOTFS_DIR/etc/timezone"

systemctl --root="$ROOTFS_DIR" set-default graphical.target
systemctl --root="$ROOTFS_DIR" enable \
  NetworkManager.service \
  bluetooth.service \
  systemd-timesyncd.service \
  "$DISPLAY_MANAGER_SERVICE" \
  ufw.service \
  kilimanjaro-firstboot.service \
  kilimanjaro-netmeter.timer
systemctl --root="$ROOTFS_DIR" disable \
  lightdm.service \
  apt-daily.timer \
  apt-daily-upgrade.timer \
  avahi-daemon.service \
  clamav-daemon.service \
  clamav-freshclam.service \
  cups-browsed.service \
  ModemManager.service || true

systemctl --root="$ROOTFS_DIR" mask \
  apt-daily.service \
  apt-daily-upgrade.service \
  clamav-freshclam.service

if [[ -x "$ROOTFS_DIR/usr/sbin/plymouth-set-default-theme" ]]; then
  in_chroot plymouth-set-default-theme -R kilimanjaro
fi

: > "$ROOTFS_DIR/etc/machine-id"
rm -f -- "$ROOTFS_DIR/var/lib/dbus/machine-id"
restore_runtime_dns_link

log 'Kilimanjaro identity and policies applied.'
