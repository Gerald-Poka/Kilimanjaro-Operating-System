import ReadinessDetails from "../sections/status/ReadinessDetails";
import { readiness } from "../data/project";
import "../styles/sections/guides.css";

export default function ReleaseStatusPage() {
  return (
    <div className="container guide-page">
      <header className="guide-intro">
        <p className="eyebrow">RELEASE STATUS / DEVELOPMENT PREVIEW</p>
        <h1 className="page-title">
          Built to explore.
          <br />
          <span>Tested with honesty.</span>
        </h1>
        <p>
          Follow Kilimanjaro's progress toward a dependable desktop for gaming,
          creation and everyday work.
        </p>
        <div className="guide-meta">
          Version {readiness.version} · Updated {readiness.updated}
        </div>
        <div className="guide-notice">
          This is a testable development build, not a production-ready release.
          No physical machine has been qualified yet.
        </div>
      </header>
      <ReadinessDetails />
    </div>
  );
}
