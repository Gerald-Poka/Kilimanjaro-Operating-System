import { Link } from "react-router-dom";
import GuideSection from "../../components/GuideSection";

export default function VerifyDownload() {
  return (
    <GuideSection id="verify-download" number="02" title="Download & verify">
      <ol>
        <li>
          Open <Link to="/downloads">Downloads</Link>. Download the development
          ISO and its SHA256SUMS file from the same release. If no release is
          staged, downloads are unavailable.
        </li>
        <li>
          Keep both files in the same folder. Open a terminal in that folder and
          run:
        </li>
      </ol>
      <pre>
        <code>sha256sum -c SHA256SUMS</code>
      </pre>
      <p>
        The ISO should report <code>OK</code>. If it reports a mismatch, stop:
        do not boot or install that file. Download it again and compare against
        the published checksum. If your system lacks sha256sum, use a SHA-256
        file-hashing tool and compare the entire result against SHA256SUMS.
      </p>
      <div className="guide-notice">
        A checksum detects a changed download, but does not authenticate its
        publisher. Release GPG signing is pending; there is no published trusted
        project key/signature to verify yet. Secure Boot is a separate
        boot-chain check, not release authentication.
      </div>
      <p>
        Never run instructions from an unknown download mirror or enter an
        account password/API key to obtain the ISO. Public hosting and a stable
        release are not yet established.
      </p>
    </GuideSection>
  );
}
