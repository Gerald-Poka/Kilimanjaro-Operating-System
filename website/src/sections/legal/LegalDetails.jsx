import { Link } from "react-router-dom";
import GuideSection from "../../components/GuideSection";

export default function LegalDetails() {
  return (
    <div className="legal-details">
      <GuideSection
        id="risks"
        number="01"
        title="Installation & reliability risks"
      >
        <p>
          Installing, partitioning, updating or restoring a system can cause
          data loss, downtime or incompatibility. Back up first, use a
          disposable VM and inspect the destination disk before confirming any
          write. You are responsible for deciding whether the build is
          appropriate for your situation.
        </p>
        <p>
          No promise is made that all hardware, applications, games, anti-cheat
          systems, security controls or document formats will work. Physical
          hardware, NVIDIA/hybrid graphics, ROG controls, recovery and parts of
          localization are not qualified. Read the{" "}
          <Link to="/documentation">documentation and current limitations</Link>
          .
        </p>
        <p>
          These notices do not override applicable component licenses or any
          statutory rights or obligations that cannot lawfully be excluded.
          Public release terms should receive appropriate legal review; this
          page is a plain-language project notice, not legal advice or a
          finalized license agreement.
        </p>
      </GuideSection>
      <GuideSection
        id="licenses"
        number="02"
        title="Licenses, credits & redistribution"
      >
        <p>
          Gerald Ndyamukama is the Kilimanjaro project author. Upstream
          developers retain authorship and copyright in their components.
          Rebranding does not replace KDE’s application authors or remove
          third-party copyright notices.
        </p>
        <p>
          Each package has its own terms. Debian package copyright/license
          information is normally available under{" "}
          <code>/usr/share/doc/&lt;package&gt;/copyright</code>, with common
          license texts in <code>/usr/share/common-licenses</code>. Consult the
          package itself, not a blanket assumption that every included app has
          the same license. See{" "}
          <a href="https://www.debian.org/legal/disclaimer/">
            Debian’s package-license guidance
          </a>{" "}
          and{" "}
          <a href="https://www.debian.org/legal/licenses/">
            archive license categories
          </a>
          .
        </p>
        <p>
          Original Kilimanjaro program code is licensed under GPL-3.0-only.
          Existing file-specific and upstream licenses still apply; this does
          not relicense every package in the ISO. Artwork, documentation and
          third-party provenance require their own license/permission review.
          Before public distribution, verify package-specific redistribution,
          attribution and corresponding-source obligations. Read the{" "}
          <a href="/licensing.txt">project licensing scope</a> and{" "}
          <a href="/LICENSE.txt">complete GPL-3.0 license</a>.
        </p>
        <p>
          Proprietary apps, firmware, codecs, fonts and drivers may have
          additional license or regional restrictions. Obtain any necessary
          permissions and comply with applicable law; availability in a
          repository is not a guarantee of permission for every use or
          redistribution.
        </p>
      </GuideSection>
      <GuideSection
        id="services"
        number="03"
        title="External services & privacy"
      >
        <p>
          Optional apps may require vendor accounts, subscriptions, API
          credentials or paid content. AI tools and online services can send
          prompts, documents and usage data to their providers. Review each
          service’s terms and privacy policy before signing in or sharing
          sensitive data.
        </p>
        <p>
          The website does not currently include an analytics integration.
          Hosting providers may keep request logs, and following vendor, email
          or WhatsApp links leaves the site for those services. This is not a
          promise that external services collect no data.
        </p>
        <p>
          Download and update traffic can incur internet/mobile-data charges.
          Metered defaults reduce some automatic activity, but cannot guarantee
          zero background traffic. Support reports should omit credentials and
          other personal information.
        </p>
      </GuideSection>
      <GuideSection
        id="trust"
        number="04"
        title="Release trust & project contact"
      >
        <p>
          The current ISO is a development artifact, not a certified secure or
          stable release. A SHA-256 checksum checks file consistency;
          authenticated project GPG release signing is still pending. A signed
          Secure Boot chain does not authenticate the entire ISO or every
          installed application.
        </p>
        <p>
          See <Link to="/release-status">Release status</Link> for passed checks
          and the remaining installation, hardware, graphics and recovery gates.
        </p>
        <p>
          Questions about this notice or component attribution can be sent to{" "}
          <a href="mailto:geraldndyamukama39@gmail.com">
            geraldndyamukama39@gmail.com
          </a>
          . No response-time guarantee is offered.
        </p>
        <div className="guide-notice">
          Before a public release: complete testing, establish the
          release-signing key, review artwork/third-party licensing and
          distribution/legal/privacy requirements. Do not present this
          development notice as a finalized EULA.
        </div>
      </GuideSection>
    </div>
  );
}
