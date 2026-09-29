#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_LIB_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(cd -- "$SCRIPT_LIB_DIR/../.." && pwd)

# shellcheck source=../../config/build.env
source "$PROJECT_ROOT/config/build.env"

readonly BUILD_DIR=${KILIMANJARO_BUILD_DIR:-"$PROJECT_ROOT/build"}
readonly ROOTFS_DIR="$BUILD_DIR/rootfs"
readonly ISO_STAGING_DIR="$BUILD_DIR/iso"
readonly OUTPUT_DIR=${KILIMANJARO_OUTPUT_DIR:-"$PROJECT_ROOT/output"}
readonly ISO_PATH="$OUTPUT_DIR/$ISO_BASENAME"

CHROOT_MOUNTS=()

log() {
  printf '[kilimanjaro] %s\n' "$*"
}

die() {
  printf '[kilimanjaro] ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  [[ ${EUID:-$(id -u)} -eq 0 ]] || die 'This stage must run as root.'
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

require_rootfs() {
  [[ -f "$ROOTFS_DIR/etc/debian_version" ]] || \
    die "No bootstrapped root filesystem at $ROOTFS_DIR"
  [[ -L "$ROOTFS_DIR/lib" && $(readlink "$ROOTFS_DIR/lib") == usr/lib ]] || \
    die 'The Debian merged-/usr /lib symlink is missing. Repair the build root before proceeding.'
  for system_file in etc/passwd usr/bin/mount; do
    [[ $(stat -c %u "$ROOTFS_DIR/$system_file") == 0 ]] || \
      die "Root ownership was lost on $ROOTFS_DIR/$system_file. Rebuild in the container build volume or on a filesystem that preserves Unix ownership."
  done
}

assert_build_path() {
  local target resolved_target resolved_build
  target=$1
  resolved_target=$(realpath -m -- "$target")
  resolved_build=$(realpath -m -- "$BUILD_DIR")

  [[ "$resolved_target" == "$resolved_build" || "$resolved_target" == "$resolved_build/"* ]] || \
    die "Refusing to modify path outside the build directory: $resolved_target"
  [[ "$resolved_target" != "$PROJECT_ROOT" && "$resolved_target" != / ]] || \
    die "Refusing unsafe build path: $resolved_target"
}

reset_build_directory() {
  local target=$1
  assert_build_path "$target"
  if [[ -e "$target" ]]; then
    rm -rf -- "$target"
  fi
  install -d -m 0755 "$target"
}

load_package_list() {
  local list_file=$1
  awk 'NF && $1 !~ /^#/ { print $1 }' "$list_file"
}

mount_chroot_filesystems() {
  local destination filesystem source options
  local mounts=(
    '/dev|none|/dev|--rbind'
    '/proc|proc|proc|-t'
    '/sys|sysfs|sysfs|-t'
    '/run|tmpfs|tmpfs|-t'
  )

  for entry in "${mounts[@]}"; do
    IFS='|' read -r destination filesystem source options <<< "$entry"
    install -d -m 0755 "$ROOTFS_DIR$destination"
    if mountpoint -q "$ROOTFS_DIR$destination"; then
      continue
    fi
    if [[ "$options" == '-t' ]]; then
      mount -t "$filesystem" "$source" "$ROOTFS_DIR$destination"
    else
      mount "$options" "$source" "$ROOTFS_DIR$destination"
    fi
    CHROOT_MOUNTS+=("$ROOTFS_DIR$destination")
  done
}

unmount_chroot_filesystems() {
  local index
  for ((index=${#CHROOT_MOUNTS[@]}-1; index>=0; index--)); do
    umount -R "${CHROOT_MOUNTS[$index]}" 2>/dev/null || true
  done
  CHROOT_MOUNTS=()
}

prepare_chroot_dns() {
  rm -f -- "$ROOTFS_DIR/etc/resolv.conf"
  cp --dereference /etc/resolv.conf "$ROOTFS_DIR/etc/resolv.conf"
}

restore_runtime_dns_link() {
  rm -f -- "$ROOTFS_DIR/etc/resolv.conf"
  ln -s /run/NetworkManager/resolv.conf "$ROOTFS_DIR/etc/resolv.conf"
}

in_chroot() {
  chroot "$ROOTFS_DIR" /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    "$@"
}
