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
EOF

mapfile -t packages < <(
  for package_file in \
    "$PROJECT_ROOT/config/packages/base.list" \
    "$PROJECT_ROOT/config/packages/desktop.list" \
    "$PROJECT_ROOT/config/packages/apps.list"; do
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
