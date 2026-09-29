import GuideSection from "../../components/GuideSection";

export default function UpdatesRecovery() {
  return (
    <GuideSection
      id="updates-recovery"
      number="06"
      title="Updates, backups & recovery"
    >
      <h3>Update deliberately</h3>
      <p>
        Automatic APT upgrade timers are disabled by the project’s low-data
        defaults. Manual control is not permission to ignore security updates:
        schedule checks on a trusted connection with enough data and power.
      </p>
      <ol>
        <li>
          Back up personal files and take a VM snapshot before testing upgrades.
        </li>
        <li>
          Open Discover, refresh updates and review the proposed changes. Finish
          one package operation before starting another.
        </li>
        <li>
          Allow the update to complete without forcing shutdown. Reboot if
          requested and verify login, desktop, audio and network.
        </li>
        <li>
          Repository applications, Flatpaks and manually downloaded vendor apps
          can have different update paths. Check each vendor’s instructions; do
          not mix arbitrary Debian releases or unknown repositories.
        </li>
      </ol>
      <h3>Plan recovery before you need it</h3>
      <p>
        Timeshift is included, but snapshots require configuration and a
        suitable destination. A system snapshot is not a substitute for a
        separate backup of your personal files. End-to-end snapshot restore and
        recovery-update testing are still pending.
      </p>
      <ul>
        <li>
          In a disposable VM, keep a known-good VM snapshot before an update and
          test reverting it. Restoring returns the guest to that earlier state
          and discards later guest changes.
        </li>
        <li>
          If an update fails, preserve the error/log. If the installed boot menu
          offers an earlier kernel, try it without removing the current one. Do
          not format the disk or run a filesystem repair blindly.
        </li>
        <li>
          If the VM cannot boot, use its known-good snapshot, or attach the live
          ISO for diagnosis. Avoid reinstalling over files you have not backed
          up.
        </li>
      </ul>
      <div className="guide-notice">
        There is no published Kilimanjaro APT repository or supported signed
        offline update bundle yet. Recovery is not guaranteed; do not depend on
        this development build for irreplaceable work.
      </div>
    </GuideSection>
  );
}
