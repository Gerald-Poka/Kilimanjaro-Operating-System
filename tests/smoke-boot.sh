#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../config/build.env
source "$ROOT_DIR/config/build.env"

iso_path="$ROOT_DIR/output/$ISO_BASENAME"
report_dir="$ROOT_DIR/build/test/${SMOKE_BOOT_MEDIA:-optical}"
if [[ ${SMOKE_FIRMWARE:-bios} != bios ]]; then
  report_dir="$ROOT_DIR/build/test/${SMOKE_FIRMWARE}-${SMOKE_BOOT_MEDIA:-optical}"
fi
report_dir=${SMOKE_REPORT_DIR:-$report_dir}
log_path="$report_dir/smoke-boot.log"
timeout_seconds=${SMOKE_TIMEOUT:-300}
memory=${SMOKE_MEMORY:-2048}
cpus=${SMOKE_CPUS:-2}
boot_media=${SMOKE_BOOT_MEDIA:-optical}
qemu_pid=''
serial_dir=$(mktemp -d /tmp/kilimanjaro-smoke-XXXXXX)

cleanup() {
  if [[ -n "$qemu_pid" ]] && kill -0 "$qemu_pid" 2>/dev/null; then
    kill "$qemu_pid" 2>/dev/null || true
    wait "$qemu_pid" 2>/dev/null || true
  fi
  rm -f -- "$serial_dir/serial.sock" "$serial_dir/OVMF_VARS.fd"
  rmdir -- "$serial_dir" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

command -v qemu-system-x86_64 >/dev/null 2>&1 || {
  printf 'FAIL: qemu-system-x86_64 is required for the VM smoke test\n' >&2
  exit 1
}
for artifact in "$iso_path"; do
  [[ -f "$artifact" ]] || {
    printf 'FAIL: missing build artifact: %s\n' "$artifact" >&2
    printf 'Run make container-iso before the smoke test.\n' >&2
    exit 1
  }
done

case "$boot_media" in
  optical) media_options=(-cdrom "$iso_path" -boot order=d) ;;
  usb)
    media_options=(-device qemu-xhci
      -drive "if=none,id=liveusb,format=raw,readonly=on,file=$iso_path"
      -device usb-storage,drive=liveusb,bootindex=1 -boot menu=on)
    ;;
  *) printf 'FAIL: SMOKE_BOOT_MEDIA must be optical or usb\n' >&2; exit 1 ;;
esac

install -d -m 0755 "$report_dir"
: > "$log_path"

machine_options=(-machine pc)
firmware_options=()
vga=virtio
case ${SMOKE_FIRMWARE:-bios} in
  bios) ;;
  secureboot)
    ovmf_code=${OVMF_CODE:-/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd}
    ovmf_vars=${OVMF_VARS_TEMPLATE:-/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd}
    [[ -r "$ovmf_code" && -r "$ovmf_vars" ]] || {
      printf 'FAIL: supply enrolled-key OVMF_CODE and OVMF_VARS_TEMPLATE for Secure Boot\n' >&2
      exit 1
    }
    cp "$ovmf_vars" "$serial_dir/OVMF_VARS.fd"
    machine_options=(-machine q35,smm=on -global driver=cfi.pflash01,property=secure,value=on)
    firmware_options=(-drive "if=pflash,format=raw,readonly=on,file=$ovmf_code"
      -drive "if=pflash,format=raw,file=$serial_dir/OVMF_VARS.fd")
    vga=std
    ;;
  *) printf 'FAIL: SMOKE_FIRMWARE must be bios or secureboot\n' >&2; exit 1 ;;
esac

acceleration=(-accel tcg,thread=multi -cpu max)
monitor_options=()
if [[ -n ${SMOKE_QMP_SOCKET:-} ]]; then
  monitor_options=(-qmp "unix:$SMOKE_QMP_SOCKET,server=on,wait=off")
fi
if [[ ${SMOKE_ACCEL:-auto} != tcg && -r /dev/kvm && -w /dev/kvm ]]; then
  acceleration=(-enable-kvm -cpu host)
fi

printf 'Starting offline %s VM smoke test (timeout: %ss)...\n' "$boot_media" "$timeout_seconds"
qemu-system-x86_64 \
  "${acceleration[@]}" \
  "${machine_options[@]}" \
  "${firmware_options[@]}" \
  -m "$memory" \
  -smp "$cpus" \
  -vga "$vga" \
  "${media_options[@]}" \
  -nic none \
  -display none \
  -chardev "socket,id=serial0,path=$serial_dir/serial.sock,server=on,wait=off,logfile=$log_path" \
  -serial chardev:serial0 \
  -monitor none \
  "${monitor_options[@]}" \
  -no-reboot \
  >"$report_dir/smoke-qemu.log" 2>&1 &
qemu_pid=$!

if python3 "$ROOT_DIR/tests/guest-boot-probe.py" "$serial_dir/serial.sock" "$LIVE_USERNAME" "$timeout_seconds" "${SMOKE_FIRMWARE:-bios}"; then
  printf 'Log: %s\n' "$log_path"
else
  tail -n 60 "$log_path" >&2
  exit 1
fi
