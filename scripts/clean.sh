#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
assert_build_path "$BUILD_DIR"

unmount_chroot_filesystems

if mountpoint -q "$ROOTFS_DIR/dev" || \
   mountpoint -q "$ROOTFS_DIR/proc" || \
   mountpoint -q "$ROOTFS_DIR/sys" || \
   mountpoint -q "$ROOTFS_DIR/run"; then
  die 'A rootfs mount is still active; refusing to remove the build directory.'
fi

rm -rf -- "$BUILD_DIR"
log "Removed generated build state: $BUILD_DIR"

