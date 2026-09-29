export const repositoryUrl =
  "https://github.com/Gerald-Poka/Kilimanjaro-Operating-System";

export const readiness = {
  version: "0.1.0",
  updated: "30 September 2026",
  sha256: "3c6ff34476753d65ad1a70151f8418518b290526da825f64bb41ead6dbfd692c",
  passed: [
    "BIOS optical live boot: graphical target, SDDM and Plasma running.",
    "BIOS virtual USB live boot: graphical target, SDDM and Plasma running.",
    "UEFI virtual USB live boot: Secure Boot enabled and desktop services running.",
    "ISO checksum, embedded package baseline and signed boot-image inspection.",
    "Six release-signing regression tests using disposable test keys.",
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
      "Graphics & gaming",
      "Test NVIDIA drivers and Secure Boot enrollment, Intel/AMD acceleration, hybrid graphics, ASUS ROG controls, games and recording.",
    ],
    [
      "Updates & recovery",
      "Verify kernel updates, failed-update recovery and snapshot restoration on disposable systems. Keep personal backups separately.",
    ],
    [
      "Everyday features",
      "Validate application installation, calls and screen sharing, trusted-network KDE Connect pairing, network monitoring and Kiswahili translation.",
    ],
    [
      "Public release trust",
      "Establish the owner's GPG release key and trusted fingerprint, verify release signatures, and finish licensing, provenance and redistribution checks.",
    ],
  ],
};
