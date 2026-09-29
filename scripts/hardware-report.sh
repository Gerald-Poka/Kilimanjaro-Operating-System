#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Gerald Ndyamukama
set -euo pipefail

if [[ ${1:-} == --help ]]; then
  printf 'Usage: bash hardware-report.sh [new-report-file]\n'
  printf 'Read-only hardware/boot diagnostics. No installs, repairs or disk writes.\n'
  printf 'Only an explicitly requested new report file is created. Review it before sharing.\n'
  exit 0
fi
[[ $# -le 1 ]] || { printf 'ERROR: expected zero or one report path\n' >&2; exit 1; }
if [[ $# == 1 ]]; then
  # Do not overwrite a user report or follow an existing destination symlink.
  umask 077
  set -o noclobber
  exec > "$1"
fi

section() { printf '\n## %s\n' "$1"; }
check() {
  local program=$1
  shift
  if command -v "$program" >/dev/null 2>&1; then
    "$program" "$@" 2>&1 || printf '[Check failed or access unavailable: %s]\n' "$program"
  else
    printf '[Not installed: %s]\n' "$program"
  fi
}

printf 'Kilimanjaro physical-machine diagnostic report\n'
printf 'This report is evidence, not a compatibility certification.\n'
printf 'Review device names, mount paths and errors before sharing. No automatic upload.\n'
section 'System and kernel'
[[ ! -r /etc/os-release ]] || sed -n '/^\(NAME\|VERSION_ID\|ID\|PRETTY_NAME\)=/p' /etc/os-release
check uname -r
check uname -m
section 'Manufacturer and model (no serial numbers)'
for field in sys_vendor product_name; do
  if [[ -r /sys/class/dmi/id/$field ]]; then
    printf '%s: ' "$field"
    sed -n '1p' "/sys/class/dmi/id/$field"
  fi
done
section 'Memory'
check free -h
section 'PCI device identities and active drivers'
check lspci -nnk
section 'Storage layout (read-only; no UUID or serial inventory)'
check lsblk -e 7 -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS
section 'Root filesystem'
check findmnt -n -o SOURCE,FSTYPE,OPTIONS /
section 'Firmware and Secure Boot'
if [[ -d /sys/firmware/efi ]]; then printf 'Boot mode: UEFI\n'; else printf 'Boot mode: legacy BIOS\n'; fi
check mokutil --sb-state
section 'Failed services'
check systemctl --failed --no-pager
section 'Network device state (no IP/MAC inventory)'
check nmcli -t -f DEVICE,TYPE,STATE device status
section 'Graphics'
check vulkaninfo --summary
section 'Qualification still requires manual tests'
printf '%s\n' 'Check live USB boot, installed reboot, display/scaling, Wi-Fi, audio/mic, Bluetooth,' \
  'suspend/resume, battery/power, external display, graphics acceleration, updates and recovery.'
