#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

errors=0
warnings=0

check_command() {
  local command_name=$1
  local package_hint=$2
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'ok      %-22s %s\n' "$command_name" "$(command -v "$command_name")"
  else
    printf 'missing %-22s install %s\n' "$command_name" "$package_hint"
    errors=$((errors + 1))
  fi
}

printf 'Kilimanjaro OS build host check\n'
printf 'Project: %s\n' "$PROJECT_ROOT"
printf 'Build:   %s\n\n' "$BUILD_DIR"

check_command debootstrap debootstrap
check_command chroot coreutils
check_command mksquashfs squashfs-tools
check_command grub-mkrescue grub-common
check_command xorriso xorriso
check_command sha256sum coreutils
check_command rsync rsync
check_command gpg gnupg
check_command findmnt util-linux
check_command mountpoint util-linux

if [[ $(uname -m) != x86_64 ]]; then
  printf 'warning %-22s amd64 builds are currently tested only on x86_64 hosts\n' architecture
  warnings=$((warnings + 1))
fi

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'warning %-22s full builds require root (or the privileged build container)\n' privileges
  warnings=$((warnings + 1))
fi

available_kib=$(df -Pk "$PROJECT_ROOT" | awk 'NR == 2 { print $4 }')
if [[ "$available_kib" -lt 62914560 ]]; then
  printf 'warning %-22s less than 60 GiB is available\n' disk-space
  warnings=$((warnings + 1))
else
  printf 'ok      %-22s at least 60 GiB is available\n' disk-space
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}:${ID_LIKE:-}" in
    debian:*|ubuntu:*|*:debian*|*:ubuntu*)
      printf 'ok      %-22s %s\n' host-os "${PRETTY_NAME:-unknown}"
      ;;
    *)
      printf 'warning %-22s %s; use make container-iso\n' host-os "${PRETTY_NAME:-unknown}"
      warnings=$((warnings + 1))
      ;;
  esac
fi

printf '\nResult: %d error(s), %d warning(s)\n' "$errors" "$warnings"
[[ "$errors" -eq 0 ]]

