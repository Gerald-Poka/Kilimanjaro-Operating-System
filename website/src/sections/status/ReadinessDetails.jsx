import { Link } from "react-router-dom";
import GuideSection from "../../components/GuideSection";
import { readiness, repositoryUrl } from "../../data/project";

export default function ReadinessDetails() {
  return (
    <div className="legal-details">
      <GuideSection id="passed-checks" number="01" title="What has passed">
        <ul>
          {readiness.passed.map((check) => (
            <li key={check}>{check}</li>
          ))}
        </ul>
        <p>
          These are virtual-media and inspection checks, not proof of physical
          hardware compatibility or visual quality. An earlier ISO completed an
          offline UEFI installation and console login; that does not qualify the
          rebuilt image's installed desktop.
        </p>
        <div className="guide-notice">
          The current KVM Secure Boot rerun failed with an unsupported-image
          error. Software-emulated testing is a separate result, not a fix for
          that failure or a guarantee of physical firmware compatibility.
        </div>
        <div className="guide-notice">{readiness.notice}</div>
        <p>Tested development ISO SHA-256:</p>
        <pre>
          <code>{readiness.sha256}</code>
        </pre>
      </GuideSection>
      <GuideSection
        id="release-gates"
        number="02"
        title="What remains before a recommended release"
      >
        <div className="legal-cards">
          {readiness.pending.map(([title, description]) => (
            <article key={title}>
              <h3>{title}</h3>
              <p>{description}</p>
            </article>
          ))}
        </div>
      </GuideSection>
      <GuideSection
        id="safe-testing"
        number="03"
        title="A safe path to real hardware"
      >
        <p>
          The goal is installation on 64-bit Intel/AMD PCs capable of running
          Ubuntu 26.04. This is a compatibility target, not a guarantee:
          Kilimanjaro uses Debian 13 packages with the stable 6.12 LTS kernel,
          so its driver and firmware baseline still differs.
        </p>
        <p>
          Start in a disposable VM. Physical testing is deferred until suitable
          hardware is available. Flashing a USB erases its contents; live boot
          can still access internal disks. Do not install onto your main
          computer or overwrite a drive without verified backups and an
          explicitly confirmed destination.
        </p>
        <p>
          A signed Secure Boot chain does not authenticate the whole ISO.
          Project GPG release signing is pending; a checksum alone does not
          prove publisher identity.
        </p>
        <div className="guide-links">
          <Link to="/documentation">Read the testing documentation</Link>
          <a href={`${repositoryUrl}/blob/main/docs/READINESS-REVIEW.md`}>
            Source readiness review ↗
          </a>
          <a href={repositoryUrl}>Browse the project on GitHub ↗</a>
        </div>
      </GuideSection>
    </div>
  );
}
