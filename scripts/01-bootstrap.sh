#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

require_root
require_command debootstrap

if [[ -f "$ROOTFS_DIR/etc/debian_version" ]]; then
  log "Bootstrap already exists at $ROOTFS_DIR; skipping."
  exit 0
fi

if [[ -d "$ROOTFS_DIR" ]] && [[ -n $(find "$ROOTFS_DIR" -mindepth 1 -maxdepth 1 -print -quit) ]]; then
  die "Rootfs directory exists but is not a completed bootstrap: $ROOTFS_DIR"
fi

install -d -m 0755 "$BUILD_DIR" "$OUTPUT_DIR"

log "Bootstrapping Debian $DEBIAN_SUITE ($ARCH) from $DEBIAN_MIRROR"
debootstrap \
  --arch="$ARCH" \
  --variant=minbase \
  --components=main,contrib,non-free,non-free-firmware \
  --include=ca-certificates,debian-archive-keyring,gnupg \
  "$DEBIAN_SUITE" \
  "$ROOTFS_DIR" \
  "$DEBIAN_MIRROR"

log 'Base root filesystem created.'

