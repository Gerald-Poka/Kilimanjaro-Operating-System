#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

case ${1:-} in
  -h|--help)
    cat <<'EOF'
Usage: ./scripts/run-vm.sh [--bios|--uefi|--secureboot]

Launch the generated Kilimanjaro live ISO in a graphical QEMU window.

Environment overrides:
  VM_MEMORY=4096       RAM in MiB
  VM_CPUS=4            virtual CPU count
  VM_FIRMWARE=bios     bios, uefi or secureboot
  VM_DRY_RUN=0         set to 1 to print the QEMU command without launching
  OVMF_CODE=path       custom UEFI code image
  OVMF_VARS_TEMPLATE=path
  VM_DISK=path         persistent disposable VM disk (default: build/vm/<firmware>/disk.img)
  VM_HEADLESS=1        disable the graphical window for automated tests
  VM_NETWORK=none      disable networking for offline installation tests
  VM_QMP_SOCKET=path   enable a QMP control socket
  VM_SERIAL_SOCKET=path enable a serial-console socket and log
  VM_ACCEL=tcg         use software emulation when KVM is unavailable or unstable
  VM_VGA=adapter       virtual graphics (default: std with Secure Boot, virtio otherwise)
  VM_BOOT=disk         boot an existing installed disk without the ISO
EOF
    exit 0
    ;;
  --bios)
    VM_FIRMWARE=bios
    ;;
  --uefi)
    VM_FIRMWARE=uefi
    ;;
  --secureboot)
    VM_FIRMWARE=secureboot
    ;;
  '')
    ;;
  *)
    die "Unknown option: $1 (use --help)"
    ;;
esac

require_command qemu-system-x86_64
if [[ ${VM_BOOT:-live} != disk ]]; then
  [[ -f "$ISO_PATH" ]] || die "ISO not found: $ISO_PATH (run make container-iso first)"
fi

memory=${VM_MEMORY:-4096}
cpus=${VM_CPUS:-4}
firmware=${VM_FIRMWARE:-bios}
vm_vga=${VM_VGA:-virtio}
if [[ "$firmware" == secureboot ]]; then
  vm_vga=${VM_VGA:-std}
fi
vm_state_dir="$BUILD_DIR/vm/$firmware"
vm_disk=${VM_DISK:-"$vm_state_dir/disk.img"}
machine_options=(-machine pc)

acceleration=(-accel tcg,thread=multi -cpu max)
if [[ ${VM_ACCEL:-auto} != tcg && -r /dev/kvm && -w /dev/kvm ]]; then
  acceleration=(-enable-kvm -cpu host)
fi

firmware_options=()
if [[ "$firmware" == uefi || "$firmware" == secureboot ]]; then
  ovmf_code=${OVMF_CODE:-}
  ovmf_vars_template=${OVMF_VARS_TEMPLATE:-}

  if [[ "$firmware" == secureboot ]]; then
    ovmf_code=${OVMF_CODE:-/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd}
    ovmf_vars_template=${OVMF_VARS_TEMPLATE:-/usr/share/edk2/ovmf/OVMF_VARS.secboot.fd}
    machine_options=(-machine q35,smm=on -global driver=cfi.pflash01,property=secure,value=on)
  fi

  for candidate in \
    /usr/share/edk2/ovmf/OVMF_CODE.fd \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/ovmf/OVMF.fd; do
    if [[ -z "$ovmf_code" && -f "$candidate" ]]; then
      ovmf_code=$candidate
    fi
  done
  for candidate in \
    /usr/share/edk2/ovmf/OVMF_VARS.fd \
    /usr/share/OVMF/OVMF_VARS.fd; do
    if [[ -z "$ovmf_vars_template" && -f "$candidate" ]]; then
      ovmf_vars_template=$candidate
    fi
  done

  [[ -n "$ovmf_code" && -f "$ovmf_code" ]] || \
    die 'UEFI firmware was not found. Install OVMF or set OVMF_CODE.'
  [[ -n "$ovmf_vars_template" && -f "$ovmf_vars_template" ]] || \
    die 'UEFI variable template was not found. Set OVMF_VARS_TEMPLATE.'

  if [[ ${VM_DRY_RUN:-0} != 1 ]]; then
    install -d -m 0755 "$vm_state_dir"
    if [[ ! -f "$vm_state_dir/OVMF_VARS.fd" ]]; then
      cp "$ovmf_vars_template" "$vm_state_dir/OVMF_VARS.fd"
    fi
  fi
  firmware_options=(
    -drive "if=pflash,format=raw,readonly=on,file=$ovmf_code"
    -drive "if=pflash,format=raw,file=$vm_state_dir/OVMF_VARS.fd"
  )
elif [[ "$firmware" != bios ]]; then
  die "Unsupported VM_FIRMWARE value: $firmware (expected bios, uefi or secureboot)"
fi

if [[ ${VM_DRY_RUN:-0} != 1 ]]; then
  install -d -m 0755 "$vm_state_dir"
  if [[ ! -e "$vm_disk" ]]; then
    [[ ${VM_BOOT:-live} != disk ]] || die "Installed test disk not found: $vm_disk"
    truncate -s 32G "$vm_disk"
  fi
fi
network_options=(-nic user,model=virtio-net-pci)
[[ ${VM_NETWORK:-user} != none ]] || network_options=(-nic none)
test_options=()
boot_options=(-boot order=d,menu=on -cdrom "$ISO_PATH")
[[ ${VM_BOOT:-live} != disk ]] || boot_options=(-boot order=c,menu=on)
[[ ${VM_HEADLESS:-0} != 1 ]] || test_options+=(-display none)
if [[ -n ${VM_QMP_SOCKET:-} ]]; then
  test_options+=(-qmp "unix:$VM_QMP_SOCKET,server=on,wait=off")
fi
if [[ -n ${VM_SERIAL_SOCKET:-} ]]; then
  test_options+=(-chardev "socket,id=serial0,path=$VM_SERIAL_SOCKET,server=on,wait=off,logfile=$vm_state_dir/serial.log" -serial chardev:serial0)
fi

qemu_command=(qemu-system-x86_64
  "${acceleration[@]}"
  "${firmware_options[@]}"
  # The legacy PC chipset exposes the CD-ROM as a conventional IDE device,
  # which live-boot can reliably rediscover after GRUB hands off to Linux.
  "${machine_options[@]}"
  -m "$memory"
  -smp "$cpus"
  -vga "$vm_vga"
  -device qemu-xhci
  -device usb-tablet
  "${network_options[@]}"
  "${test_options[@]}"
  -drive "file=$vm_disk,format=raw,if=virtio"
  "${boot_options[@]}"
  -name "$OS_NAME $OS_VERSION_ID ($firmware)"
)

if [[ ${VM_DRY_RUN:-0} == 1 ]]; then
  printf 'Command:'
  printf ' %q' "${qemu_command[@]}"
  printf '\n'
  exit 0
fi

if [[ ${VM_HEADLESS:-0} != 1 && -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]]; then
  die 'No graphical session detected. Use make smoke-test for a headless boot test.'
fi

log "Launching $OS_NAME with $firmware firmware, ${memory} MiB RAM, and $cpus vCPU(s)"
log "Installer test disk: $vm_disk (32 GiB; retained between launches)"

exec "${qemu_command[@]}"
