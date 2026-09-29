import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import Icon from "../components/Icon";
export default function Download() {
  const [release, setRelease] = useState(null);
  const [copied, setCopied] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    fetch("/release.json", { signal: controller.signal })
      .then((response) => (response.ok ? response.json() : null))
      .then((value) => {
        if (
          value?.channel === "development" &&
          value.file === "kilimanjaro-os-0.1.0-amd64.iso" &&
          /^[a-f0-9]{64}$/.test(value.sha256)
        )
          setRelease(value);
      })
      .catch(() => {});
    return () => controller.abort();
  }, []);
  const copyHash = async () => {
    try {
      await navigator.clipboard.writeText(release.sha256);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  };
  return (
    <section className="download-section" id="download">
      <div className="container download-layout">
        <div>
          <p className="eyebrow">YOUR NEXT ADVENTURE STARTS HERE</p>
          <h1 className="page-title">
            Take the
            <br />
            <span>first step.</span>
          </h1>
          <p className="download-intro">
            Explore Kilimanjaro in a virtual machine.
            <br />
            Make yourself at home before making the switch.
          </p>
          <div className="download-facts">
            <span>
              <Icon name="layers" size={18} /> KDE Plasma desktop
            </span>
            <span>
              <Icon name="shield" size={18} /> Debian-signed UEFI boot chain
            </span>
            <span>
              <Icon name="globe" size={18} /> English UI · Kiswahili locale
            </span>
          </div>
        </div>
        <article className="release-card">
          <div className="release-top">
            <span className="release-badge">DEVELOPMENT PREVIEW</span>
            <span>amd64</span>
          </div>
          <div className="release-name">
            <img src="/brand/kilimanjaro.svg" alt="" />
            <div>
              <h3>Kilimanjaro OS</h3>
              <span>Version 0.1.0 · Live + installer</span>
            </div>
          </div>
          <p>
            For testing, not production use. BIOS optical and virtual USB live
            desktop checks pass, including UEFI virtual USB with Secure Boot
            enabled. Physical hardware, recovery and installed-desktop
            qualification remain.
          </p>
          {release?.available ? (
            <a
              className="button primary download-button"
              href={`/releases/${release.file}`}
              download
            >
              Download development ISO <Icon name="download" size={19} />
            </a>
          ) : (
            <button className="button unavailable" disabled>
              Public download not published yet
            </button>
          )}
          <p className="release-warning">
            Back up your files. Begin with a disposable VM. Release GPG signing
            is pending; Secure Boot signing and release authentication are
            different checks.
          </p>
          {release?.available && (
            <div className="checksum">
              <div>
                <a href="/releases/SHA256SUMS" download>
                  SHA256SUMS <Icon name="download" size={14} />
                </a>
                <button onClick={copyHash}>
                  {copied ? "Copied!" : "Copy SHA-256"}
                </button>
              </div>
              <code>{release.sha256}</code>
            </div>
          )}
          <Link className="release-guide" to="/getting-started">
            Read the testing guide <Icon name="arrow" size={16} />
          </Link>
          <Link className="release-guide" to="/documentation">
            Full installation documentation <Icon name="arrow" size={16} />
          </Link>
          <Link className="release-guide" to="/legal">
            Legal overview & disclaimers <Icon name="arrow" size={16} />
          </Link>
          <Link className="release-guide" to="/release-status">
            Passed tests & remaining release gates{" "}
            <Icon name="arrow" size={16} />
          </Link>
        </article>
      </div>
    </section>
  );
}
