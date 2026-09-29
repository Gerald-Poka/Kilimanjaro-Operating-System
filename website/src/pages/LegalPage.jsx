import LegalOverview from "../sections/legal/LegalOverview";
import LegalDetails from "../sections/legal/LegalDetails";
import "../styles/sections/guides.css";

export default function LegalPage() {
  return (
    <div className="container guide-page legal-page">
      <LegalOverview />
      <LegalDetails />
    </div>
  );
}
