import { Route, Routes } from "react-router-dom";
import SiteLayout from "./layouts/SiteLayout";
import HomePage from "./pages/HomePage";
import WhyPage from "./pages/WhyPage";
import ExplorePage from "./pages/ExplorePage";
import DesktopPage from "./pages/DesktopPage";
import DownloadsPage from "./pages/DownloadsPage";
import GettingStartedPage from "./pages/GettingStartedPage";
import AboutPage from "./pages/AboutPage";
import DocumentationPage from "./pages/DocumentationPage";
import LegalPage from "./pages/LegalPage";
import ReleaseStatusPage from "./pages/ReleaseStatusPage";
import NotFoundPage from "./pages/NotFoundPage";

export default function App() {
  return (
    <Routes>
      <Route element={<SiteLayout />}>
        <Route index element={<HomePage />} />
        <Route path="why-kilimanjaro" element={<WhyPage />} />
        <Route path="explore" element={<ExplorePage />} />
        <Route path="desktop" element={<DesktopPage />} />
        <Route path="downloads" element={<DownloadsPage />} />
        <Route path="getting-started" element={<GettingStartedPage />} />
        <Route path="about" element={<AboutPage />} />
        <Route path="documentation" element={<DocumentationPage />} />
        <Route path="legal" element={<LegalPage />} />
        <Route path="release-status" element={<ReleaseStatusPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
