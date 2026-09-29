import GuideSection from "../../components/GuideSection";

export default function Installation() {
  return (
    <GuideSection
      id="installation"
      number="04"
      title="Install, then boot from disk"
    >
      <p>
        The Calamares graphical installer is available through{" "}
        <strong>Install Kilimanjaro OS</strong> on the live desktop. The base
        system can be installed without a network connection.
      </p>
      <ol>
        <li>
          Choose your language, location/time zone and keyboard layout. Check
          keyboard characters before creating a password.
        </li>
        <li>
          At partitioning, confirm the disk size and identity match your
          disposable virtual disk. In the project launcher this is normally the
          32 GB virtual disk, not a host disk.
        </li>
        <li>
          Use the whole-disk option only for that empty test disk.{" "}
          <strong>
            Erase disk deletes every existing partition and file on the selected
            disk.
          </strong>{" "}
          Manual partitioning, encrypted installs and dual boot have not been
          qualified.
        </li>
        <li>
          Create your own user account and a strong password. The live account
          is not your permanent installed account.
        </li>
        <li>
          Read the final summary: destination disk, partitions, bootloader,
          locale and account. Cancel if any target is unexpected. For UEFI,
          expect an EFI system partition and Linux root filesystem.
        </li>
        <li>
          Confirm, wait for the installer’s success message, then shut down.
          Detach the ISO/eject the virtual optical drive and start the same VM
          from its disk.
        </li>
        <li>
          Log in with your new account. Check the desktop, display resizing,
          audio, network, keyboard and an administrator-authenticated action.
          Report failures rather than assuming the install is qualified.
        </li>
      </ol>
      <h3>Developer acceptance checks</h3>
      <pre>
        <code>
          {
            "# Start the installed disk without the ISO:\nVM_BOOT=disk make vm-secureboot\n\n# In the installed guest terminal:\ncat /etc/os-release\nfindmnt /\nmokutil --sb-state\nsystemctl is-active sddm"
          }
        </code>
      </pre>
      <p>
        The root filesystem must be on the installed disk, not a live overlay.
        Secure Boot should show enabled for the Secure Boot VM; SDDM should be
        active. These checks alone do not establish that the graphical desktop,
        recovery or all hardware works.
      </p>
    </GuideSection>
  );
}
