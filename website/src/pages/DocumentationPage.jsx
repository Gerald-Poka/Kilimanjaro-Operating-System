import { Link } from "react-router-dom";
import { documentationContents } from "../data/documentation";
import BeforeInstalling from "../sections/documentation/BeforeInstalling";
import VerifyDownload from "../sections/documentation/VerifyDownload";
import VirtualMachine from "../sections/documentation/VirtualMachine";
import Installation from "../sections/documentation/Installation";
import DesktopSoftware from "../sections/documentation/DesktopSoftware";
import UpdatesRecovery from "../sections/documentation/UpdatesRecovery";
import Troubleshooting from "../sections/documentation/Troubleshooting";
import "../styles/sections/guides.css";

export default function DocumentationPage() {
  return (
    <div className="container guide-page">
      <header className="guide-intro">
        <p className="eyebrow">KILIMANJARO OS / USER GUIDE</p>
        <h1 className="page-title">
          Your first steps.
          <br />
          <span>A clear path forward.</span>
        </h1>
        <p>
          From a verified download to your first desktop session. Installation,
          everyday tools, gaming, creation and recovery—in one practical guide.
        </p>
        <div className="guide-meta">
          Version 0.1.0 · Development build · Updated 30 September 2026
        </div>
        <div className="guide-notice">
          Start in a disposable virtual machine. This is not a production-ready
          release. Read the <Link to="/legal">legal overview</Link> before
          installing.
        </div>
      </header>
      <div className="guide-layout">
        <aside className="guide-sidebar">
          <nav aria-label="Documentation contents">
            <p className="eyebrow">ON THIS PAGE</p>
            {documentationContents.map(([id, title], index) => (
              <a key={id} href={`#${id}`}>
                <span>{String(index + 1).padStart(2, "0")}</span>
                {title}
              </a>
            ))}
          </nav>
          <Link className="guide-resource" to="/downloads">
            Get the development ISO ↗
          </Link>
        </aside>
        <div className="guide-articles">
          <BeforeInstalling />
          <VerifyDownload />
          <VirtualMachine />
          <Installation />
          <DesktopSoftware />
          <UpdatesRecovery />
          <Troubleshooting />
        </div>
      </div>
    </div>
  );
}
