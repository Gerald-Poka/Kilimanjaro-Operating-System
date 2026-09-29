import { whatsappUrl } from "../../data/contact";

export default function LegalOverview() {
  return (
    <header className="guide-intro">
      <p className="eyebrow">KNOW WHAT YOU’RE INSTALLING</p>
      <h1 className="page-title">
        Legal overview.
        <br />
        <span>Clear expectations.</span>
      </h1>
      <p>
        Kilimanjaro OS is an independent, hobby/development distribution created
        by <a href={whatsappUrl}>Gerald Ndyamukama</a>. Before testing it,
        understand the risks, package sources and license boundaries.
      </p>
      <div className="guide-meta">
        Development notice · Updated 30 September 2026
      </div>
      <div className="legal-cards">
        <article>
          <h2>Personal testing</h2>
          <p>
            The current build is intended for experimentation and personal
            testing. It is not recommended for mission-critical,
            business-critical or production workloads. This recommendation does
            not restrict rights granted by individual software licenses.
          </p>
        </article>
        <article>
          <h2>No promised warranty or support</h2>
          <p>
            The project offers the development build as-is, without a project
            warranty to the extent permitted by applicable law. There is no
            professional support contract, service-level agreement or guaranteed
            fix/response time.
          </p>
        </article>
        <article>
          <h2>Third-party software</h2>
          <p>
            The base uses Debian packages, including contributed/non-free
            components and firmware where configured. Optional software can use
            Flathub or vendor repositories/downloads. Their own licenses, costs
            and terms still apply.
          </p>
        </article>
        <article>
          <h2>Independent from Debian</h2>
          <p>
            Kilimanjaro is not an official Debian release or a Nobara/Fedora
            edition. It uses upstream software but is a separate project;
            mentioning Debian, KDE or other vendors does not imply their
            sponsorship or endorsement.
          </p>
        </article>
      </div>
    </header>
  );
}
