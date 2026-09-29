# Kilimanjaro installation and acceptance tests

For the direct-PC compatibility target and the owner's no-data-loss test plan,
read [physical hardware qualification](HARDWARE-QUALIFICATION.md). No installation
onto the current PC or physical USB write is authorized; physical testing is
deferred until a confirmed disposable device/test machine is available.

The image is a development build. Back up personal files before testing it on
physical hardware. The graphical Calamares installer is launched from **Install
Kilimanjaro OS** on the live desktop. It asks for language/location, keyboard,
partitioning, an account/password, and confirmation before writing to disk.
The base installation does not require internet access. Optional software
profiles and proprietary applications require separate downloads.

## Safe VM installation test

1. Run `VM_NETWORK=none make vm-secureboot` (or `make vm` for BIOS).
2. Confirm that only the intended 32 GiB virtual disk is offered. The launcher
   attaches no physical host disks. Existing test-disk contents are retained;
   **Erase disk** deliberately deletes those contents inside the VM.
3. Complete the installer, create a test account, and inspect the disk summary.
   For UEFI, expect an EFI system partition and a Linux root filesystem.
4. Confirm installation, wait for success, and shut down the guest.
5. Start `VM_BOOT=disk make vm-secureboot` to boot without any ISO attached.
6. Log in with the newly created account. Check `cat /etc/os-release`,
   `findmnt /`, `mokutil --sb-state`, and `systemctl is-active sddm`.
   The root filesystem must be on the installed disk, not a live overlay.
7. Verify that the public live account/password is not an installed account,
   the desktop launches, and the configured user can authenticate with `sudo`.

The Secure Boot VM needs enrolled Microsoft keys, not just capable firmware.
The ISO uses Debian-signed shim, GRUB and the Debian kernel. Custom kernels and
third-party NVIDIA modules require their own trusted signing/enrollment path;
the signed ISO does not automatically make those modules trusted.

## Release gates beyond a basic VM install

- BIOS installation and reboot; UEFI installation and reboot with Secure Boot.
- Encrypted installation, manual partitioning, and existing-OS dual boot.
- Update/reboot and recovery/snapshot-restore tests on a disposable install.
- Physical Wi-Fi, NVIDIA/hybrid graphics, audio, suspend and firmware matrix.
- Kiswahili translation review and supported ASUS ROG model qualification.
- Configure a real release GPG key; checksums alone do not authenticate a publisher.

The local React website preview is in `website/`. Public release publishing
remains deferred until the OS release gates are complete.
