import GuideSection from "../../components/GuideSection";

export default function BeforeInstalling() {
  return (
    <GuideSection id="before-installing" number="01" title="Before you begin">
      <p>
        Kilimanjaro OS 0.1.0 is an independent Debian 13 (Trixie)–based, 64-bit
        Intel/AMD desktop with KDE Plasma. It is not an ARM or Apple Silicon
        image. Gaming and creator profiles extend the base system; they are not
        all preinstalled.
      </p>
      <div className="guide-facts">
        <div>
          <strong>4 GB RAM</strong>
          <span>Suggested VM allocation, not a certified minimum.</span>
        </div>
        <div>
          <strong>32 GB virtual disk</strong>
          <span>Disposable test disk. Allow more for apps and games.</span>
        </div>
        <div>
          <strong>Offline base install</strong>
          <span>Optional applications and updates need internet.</span>
        </div>
      </div>
      <ul>
        <li>
          Back up documents, photos and recovery keys to a separate device.
          Confirm you can read the backup.
        </li>
        <li>
          Use a VM first. Do not attach physical host disks or enable disk
          passthrough.
        </li>
        <li>
          Allow enough host RAM and storage for both the host and guest. A VM is
          suitable for desktop testing, not a promise of native gaming
          performance.
        </li>
        <li>
          Docker is used for building the ISO; it does not replace a VM for
          testing the bootloader, installer or desktop.
        </li>
      </ul>
      <div className="guide-notice">
        Verified so far: BIOS live desktop, Secure Boot UEFI live boot, offline
        UEFI graphical installation and installed-disk boot with console login.
        Installed-desktop, BIOS installation, dual-boot, encryption, physical
        hardware and recovery qualification remain pending.
      </div>
    </GuideSection>
  );
}
