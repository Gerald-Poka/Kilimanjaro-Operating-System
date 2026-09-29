import { useEffect, useRef } from "react";
import { Outlet, useLocation } from "react-router-dom";
import Header from "../components/Header";
import Footer from "../components/Footer";
import { pageTitles } from "../data/navigation";

export default function SiteLayout() {
  const { pathname } = useLocation();
  const mainRef = useRef(null);
  const previousPath = useRef(pathname);
  useEffect(() => {
    document.title = `Kilimanjaro OS — ${pageTitles[pathname] || "Page not found"}`;
    if (previousPath.current !== pathname) {
      window.scrollTo({ top: 0, left: 0, behavior: "instant" });
      mainRef.current?.focus({ preventScroll: true });
      previousPath.current = pathname;
    }
  }, [pathname]);
  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <Header />
      <main
        id="main"
        ref={mainRef}
        tabIndex={-1}
        className={pathname === "/" ? "home-content" : "page-content"}
      >
        <Outlet />
      </main>
      <Footer />
    </>
  );
}
