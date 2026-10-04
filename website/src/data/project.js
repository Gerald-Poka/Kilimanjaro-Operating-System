export const repositoryUrl =
  "https://github.com/Gerald-Poka/Kilimanjaro-Operating-System";

export const readiness = {
  version: "0.1.0",
  updated: "30 September 2026",
  sha256: "8ddb15abc7570273bfec077da6cacf1c67249803d2d747072e6e28cf9d4a9589",
  notice:
    "This page describes the ISO with the checksum above. Source corrections made after that ISO was built are not in it yet.",
  passed: [
    "BIOS optical live boot: graphical target, SDDM and Plasma running.",
    "BIOS virtual USB live boot: graphical target, SDDM and Plasma running.",
    "UEFI virtual USB live boot (software emulation): Secure Boot enabled and desktop services running.",
    "ISO checksum, embedded package baseline and signed boot-image inspection.",
    "Six release-signing regression tests using disposable test keys.",
    "Signed local APT base-package installation and upgrade; edited configuration preserved; tampered, unsigned and expired updates rejected.",
  ],
  pending: [
    [
      "Installation",
      "Repeat installation and installed-desktop reboot checks on the latest ISO, including BIOS, UEFI and Secure Boot. Encryption and dual boot remain unqualified.",
    ],
    [
      "Real hardware",
      "Qualify Wi-Fi, Bluetooth, audio, camera, displays, input, battery and suspend/resume on physical PCs.",
    ],
    [
      "Printing & scanning",
      "Printing and scanning are now packaged, but no physical printer or scanner has been tested.",
    ],
    [
      "Graphics & gaming",
      "Test Intel/AMD acceleration, hybrid graphics, games and recording. Steam, Wine with 32-bit support, GameMode, MangoHud and the proprietary NVIDIA driver are packaged, but no title or GPU has been tested yet, and DKMS module rebuilds across kernel updates are unverified.",
    ],
    [
      "Updates & recovery",
      "Verify kernel updates, failed-update recovery and snapshot restoration on disposable systems. Keep personal backups separately.",
    ],
    [
      "Everyday features",
      "Validate application installation, calls and screen sharing, trusted-network KDE Connect pairing, network monitoring, screen reader and magnifier, and Kiswahili translation.",
    ],
    [
      "Public release trust",
      "Establish the owner's GPG release key and trusted fingerprint, verify release signatures, and finish licensing, provenance and redistribution checks.",
    ],
  ],
};
