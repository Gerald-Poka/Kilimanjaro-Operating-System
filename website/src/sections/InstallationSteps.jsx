import { Link } from "react-router-dom";

export default function InstallationSteps() {
  return (
    <section className="section container" id="guide">
      <div className="section-heading">
        <div>
          <p className="eyebrow">START SMALL. EXPLORE SAFELY.</p>
          <h1 className="page-title">
            From download
            <br />
            <span>to discovery.</span>
          </h1>
        </div>
        <p>
          No leap of faith required. Try the live environment before touching
          your computer’s disk.
        </p>
      </div>
      <ol className="steps">
        <li>
          <span>01</span>
          <h3>Check your download</h3>
          <p>
            Compare the ISO’s SHA-256 with SHA256SUMS. Release signatures will
            follow once the project key is configured.
          </p>
        </li>
        <li>
          <span>02</span>
          <h3>Create a test VM</h3>
          <p>
            Use QEMU or VirtualBox with a disposable virtual disk. Start with 4
            GB RAM and a 32 GB disk; performance varies.
          </p>
        </li>
        <li>
          <span>03</span>
          <h3>Explore, then install</h3>
          <p>
            Boot the live desktop. Open Install Kilimanjaro OS when ready, and
            select only your intended virtual disk.
          </p>
        </li>
      </ol>
      <div className="guide-links">
        <Link className="button button-primary" to="/documentation">
          Read the full documentation →
        </Link>
        <Link className="button button-secondary" to="/legal">
          Before you install: legal overview
        </Link>
      </div>
    </section>
  );
}
