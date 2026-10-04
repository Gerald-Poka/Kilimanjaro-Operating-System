#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_command chroot
require_command mountpoint
require_rootfs

check_only=false
policy_rc_created=false
case ${1:-} in
  '') ;;
  --check-only) check_only=true ;;
  *) die "Unknown argument: $1" ;;
esac

cleanup() {
  if [[ "$policy_rc_created" == true ]]; then
    rm -f -- "$ROOTFS_DIR/usr/sbin/policy-rc.d"
  fi
  restore_runtime_dns_link || true
  unmount_chroot_filesystems
}
trap cleanup EXIT INT TERM

mount_chroot_filesystems
prepare_chroot_dns

if [[ -e "$ROOTFS_DIR/usr/sbin/policy-rc.d" ]]; then
  die 'The rootfs already has /usr/sbin/policy-rc.d; refusing to overwrite it.'
fi
cat > "$ROOTFS_DIR/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod 0755 "$ROOTFS_DIR/usr/sbin/policy-rc.d"
policy_rc_created=true

cat > "$ROOTFS_DIR/etc/apt/sources.list" <<EOF
deb $DEBIAN_MIRROR $DEBIAN_SUITE main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_SUITE-updates main contrib non-free non-free-firmware
deb $DEBIAN_SECURITY_MIRROR $DEBIAN_SUITE-security main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_BACKPORTS_SUITE main contrib non-free non-free-firmware
EOF

# Backports is configured but never preferred, so nothing backported can be
# selected automatically. The kernel is intentionally left to resolve from the
# stable suite: Linux 6.12 is the newest kernel the packaged proprietary NVIDIA
# driver builds against, and there is no NVIDIA driver in any Debian suite that
# supports 7.x. See the KILIMANJARO_KERNEL_MIN_MAJOR note in config/build.env.
#
# Keeping backports reachable lets installed systems opt into single packages
# (gamescope, for example) with "apt install -t", and these files stay in the
# image so those systems inherit the same narrow policy.
install -d -m 0755 "$ROOTFS_DIR/etc/apt/preferences.d"
cat > "$ROOTFS_DIR/etc/apt/preferences.d/50-kilimanjaro-backports" <<EOF
# Kilimanjaro resolves everything from the stable suite. Backports is available
# only when explicitly requested with -t.
Package: *
Pin: release n=$DEBIAN_SUITE
Pin-Priority: 500

Package: *
Pin: release n=$DEBIAN_SUITE-updates
Pin-Priority: 500

Package: *
Pin: release n=$DEBIAN_SUITE-security
Pin-Priority: 500

Package: *
Pin: release n=$DEBIAN_BACKPORTS_SUITE
Pin-Priority: 100
EOF

# Installs default to the stable suite, which is also where the kernel and the
# matching headers come from. Both must resolve from the same suite: pairing a
# kernel with headers from a different series breaks every DKMS module build,
# including NVIDIA.
cat > "$ROOTFS_DIR/etc/apt/apt.conf.d/99-kilimanjaro-default-release" <<EOF
APT::Default-Release "$DEBIAN_SUITE";
EOF

# Steam and wine32 have no installation candidate on an amd64-only system, so
# 32-bit support is a hard requirement of the gaming pillar rather than an
# optimisation. This must run before the index refresh below, or the i386
# indexes are never fetched and the install fails later with a confusing
# "no installation candidate" error.
if ! in_chroot dpkg --print-foreign-architectures | grep -qx i386; then
  log 'Enabling i386 multiarch for Steam and 32-bit Wine titles'
  in_chroot dpkg --add-architecture i386
fi

mapfile -t packages < <(
  for package_file in "$PROJECT_ROOT"/config/packages/*.list; do
    [[ -e "$package_file" ]] || die "No package manifests found in $PROJECT_ROOT/config/packages"
    # optional.list documents deliberate exclusions; it is never installed.
    [[ $(basename "$package_file") == optional.list ]] && continue
    load_package_list "$package_file"
  done | sort -u
)

[[ ${#packages[@]} -gt 0 ]] || die 'Package selection is empty.'

log "Refreshing package indexes for $DEBIAN_SUITE"
in_chroot apt-get update

if [[ "$check_only" == true ]]; then
  package_plan="$BUILD_DIR/package-plan.txt"
  log "Resolving ${#packages[@]} selected packages without installing them"
  if ! in_chroot apt-get install --simulate --no-install-recommends "${packages[@]}" > "$package_plan"; then
    tail -n 80 "$package_plan" >&2 || true
    die 'One or more selected packages could not be resolved.'
  fi
  log "All selected packages resolve successfully; plan saved to $package_plan"
  exit 0
fi

log "Installing ${#packages[@]} selected packages"
in_chroot apt-get install -y --no-install-recommends "${packages[@]}"

in_chroot apt-get clean
rm -rf -- "$ROOTFS_DIR/var/lib/apt/lists/"*

log 'Package layer installed.'
