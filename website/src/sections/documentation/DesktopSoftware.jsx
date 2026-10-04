import { Link } from "react-router-dom";
import GuideSection from "../../components/GuideSection";

export default function DesktopSoftware() {
  return (
    <GuideSection
      id="desktop-software"
      number="05"
      title="Make the desktop yours"
    >
      <p>
        Open System Settings for display scaling, keyboard, language, network,
        notifications and appearance. Use the application launcher to open
        tools; Konsole provides a terminal. Desktop wallpaper settings offer the
        Kilimanjaro collection.
      </p>
      <h3>First boot & language</h3>
      <p>
        The first-boot service applies safe non-interactive defaults, including
        metered settings for saved network connections. Check new connections
        yourself before large downloads. Kiswahili locale support is present,
        with English fallback; the Welcome app remains English and complete
        interface translation is still in progress.
      </p>
      <h3>Daily tasks, games & creation</h3>
      <ul>
        <li>
          <strong>Included:</strong> Firefox ESR, LibreOffice, VLC, OBS, KDE
          Connect, Discover and desktop utilities. Use PulseAudio Volume Control
          (pavucontrol) for audio devices, levels and routing on the PipeWire
          audio stack.
        </li>
        <li>
          <strong>Gaming Ready profile:</strong> Steam, Wine, Lutris, GameMode,
          MangoHud and Vulkan tools. Game purchases, account sign-in and
          downloads are separate; Windows games and anti-cheat compatibility are
          not guaranteed.
        </li>
        <li>
          <strong>Creator Studio profile:</strong> additional editors such as
          Kdenlive, Blender and Krita. Test screen capture, microphone and
          export before a live stream or important recording.
        </li>
        <li>
          <strong>Optional third-party apps:</strong> Chrome, Cursor, AI agents,
          Zoom, Slack, Spotify and Discord use the installation/download methods
          shown in Welcome. WPS uses its vendor download page. Teams and Meet
          are web launchers, not bundled native Linux clients.
        </li>
      </ul>
      <ol>
        <li>
          Open Kilimanjaro Welcome and select only the software profile or
          application you need.
        </li>
        <li>
          Read the source/account/license label and storage estimate. Connect to
          suitable internet; estimates are not exact download sizes.
        </li>
        <li>
          Authenticate the installation if asked and keep the installation log
          visible until it finishes. Do not start overlapping package
          operations.
        </li>
        <li>
          Sign in directly through the application/provider. Never send
          passwords or API keys to project support.
        </li>
      </ol>
      <p>
        Browse the <Link to="/explore">application explorer</Link> for included
        versus optional status. Accounts, subscriptions, AI usage charges and
        Kiwix content packs are separate from the OS.
      </p>
      <div className="guide-notice">
        The proprietary NVIDIA driver is included along with its GSP firmware,
        so NVIDIA cards get hardware acceleration without an online install and
        without a Secure Boot module enrolment, because the target deployment
        runs with Secure Boot disabled in the PC BIOS. If you enable Secure Boot
        on a machine, the driver's self-signed dkms MOK is not enrolled and the
        modules will be rejected, so treat Secure Boot as unsupported. It is
        built by dkms, so each kernel update rebuilds the module and that
        rebuild is not yet verified. Physical hybrid graphics, ASUS ROG fan
        profiles and graphics-mode switching still need integration/testing. Do
        not apply unverified tuning scripts to your laptop.
      </div>
    </GuideSection>
  );
}
