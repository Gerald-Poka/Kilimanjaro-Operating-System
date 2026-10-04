import GuideSection from "../../components/GuideSection";

export default function Troubleshooting() {
  return (
    <GuideSection
      id="troubleshooting"
      number="07"
      title="When something goes wrong"
    >
      <h3>Stuck at dots or an initramfs prompt</h3>
      <p>
        This indicates a boot failure, not a completed installation. Check the
        ISO checksum, confirm the ISO is attached for live boot and verify the
        boot target. Record the error above the prompt. If offered, try the
        fallback graphics/live boot entry. Do not run destructive repair
        commands without identifying the cause.
      </p>
      <h3>Blank desktop or unreadable display</h3>
      <p>
        Return to the VM’s baseline graphics settings and turn off optional 3D
        acceleration. If the desktop opens, adjust resolution/scaling in System
        Settings. Record firmware mode, virtual display adapter and resolution
        so the problem can be reproduced.
      </p>
      <h3>No sound, network or game acceleration</h3>
      <p>
        Check that the VM has an audio/network device attached and is not
        intentionally offline. In pavucontrol, select the expected output/input
        and check mute. KDE’s system information describes the guest, not
        necessarily the host GPU; virtual graphics do not prove NVIDIA/ROG
        support or native gaming performance.
      </p>
      <h3>Network usage & security</h3>
      <p>
        The network meter records interface byte counters. The tray can request
        on-demand NetHogs process attribution with administrator authentication;
        persistent per-process history is not implemented. The included firewall
        (UFW) helps, but neither it nor AppArmor makes a machine safe. No
        antivirus ships in the image: ClamAV was removed because it cannot work
        without downloaded signature databases, which an offline image cannot
        carry. Keep updates current and install apps from sources you trust.
      </p>
      <h3>Report a reproducible issue</h3>
      <p>
        Email{" "}
        <a href="mailto:geraldndyamukama39@gmail.com">
          geraldndyamukama39@gmail.com
        </a>{" "}
        with the ISO version, VM application/firmware, steps taken, expected
        result and exact error. For an installed guest, these read-only commands
        can help:
      </p>
      <pre>
        <code>
          {
            "cat /etc/os-release\nuname -r\nfindmnt /\nsystemctl --failed\njournalctl -b -p err --no-pager"
          }
        </code>
      </pre>
      <p>
        Review logs/screenshots before sharing: redact passwords, keys, serial
        numbers, account identifiers, IP addresses and personal filenames. Help
        is best-effort with no guaranteed response time. Full hardware
        compatibility, recovery, translation and release-signing validation
        remain release gates.
      </p>
    </GuideSection>
  );
}
