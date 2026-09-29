import GuideSection from "../../components/GuideSection";

export default function VirtualMachine() {
  return (
    <GuideSection
      id="virtual-machine"
      number="03"
      title="Set up a virtual machine"
    >
      <h3>Using your VM application</h3>
      <ol>
        <li>
          Create a new Linux/Debian 64-bit VM in QEMU or VirtualBox. Exact
          labels vary by application. The recorded installation test used QEMU,
          not VirtualBox.
        </li>
        <li>
          Allocate around 4 GB RAM, 2–4 virtual CPUs and a new 32 GB virtual
          disk. Keep the disk disposable and clearly name it Kilimanjaro Test.
        </li>
        <li>
          Attach the verified ISO to the virtual optical drive. Use UEFI for the
          installation path tested so far; keep firmware mode unchanged after
          installation.
        </li>
        <li>
          For a baseline display test, disable optional 3D acceleration. Leave
          networking disconnected if you want to verify an offline base
          installation.
        </li>
        <li>
          Start the VM, select the live boot entry and wait for the desktop.
          Live-session changes are temporary unless stored on a separate
          persistent disk.
        </li>
      </ol>
      <h3>Using the project’s QEMU launcher</h3>
      <p>
        For developers with this repository, QEMU and suitable OVMF firmware
        installed, run these from the project root. The launcher creates/reuses
        a persistent 32 GB test disk; installer erasure also removes previous
        tests on that disk.
      </p>
      <pre>
        <code>
          {
            "VM_NETWORK=none make vm-secureboot\n# Or test the legacy BIOS live environment:\nmake vm"
          }
        </code>
      </pre>
      <p>
        Secure Boot testing requires firmware with enrolled Microsoft keys. The
        ISO uses Debian-signed shim, GRUB and kernel components. Custom kernels
        and third-party NVIDIA modules need a separate trusted
        signing/enrollment path.
      </p>
      <div className="guide-notice">
        Physical USB installation is not qualified yet. Do not use this build to
        replace your daily OS or attempt dual boot. USB flashing overwrites the
        selected device; physical-disk instructions will be expanded after
        hardware and recovery testing.
      </div>
      <h3>Later: test on a physical PC without installing</h3>
      <p>
        Kilimanjaro is intended for direct installation on supported Intel/AMD
        PCs, not only virtual machines. For now, physical testing is deferred. A
        32 GB flash drive can later serve as live boot media, but writing the
        ISO erases that flash drive. Confirm its exact identity and approve the
        overwrite first. Boot the live session only; do not open the installer
        or mount/edit internal disks when keeping your current system unchanged.
      </p>
      <p>
        Ubuntu 26.04 compatibility is a target, not a guarantee: Ubuntu ships a
        newer kernel than this Debian-based image, and this ISO is amd64 only.
        Live USB testing does not qualify installation, proprietary graphics,
        updates or recovery. We will keep the development warning until those
        checks have evidence.
      </p>
    </GuideSection>
  );
}
