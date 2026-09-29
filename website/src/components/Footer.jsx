import { Link } from "react-router-dom";
import { whatsappUrl } from "../data/contact";
import { repositoryUrl } from "../data/project";

export default function Footer() {
  return (
    <footer className="container footer">
      <Link className="brand" to="/">
        <img src="/brand/kilimanjaro.svg" alt="" />
        <span>KILIMANJARO OS</span>
      </Link>
      <p>Made in Tanzania. Built on open source.</p>
      <nav className="footer-links" aria-label="Resources">
        <Link to="/documentation">Documentation</Link>
        <Link to="/legal">Legal overview</Link>
        <Link to="/release-status">Release status</Link>
        <a href={repositoryUrl}>GitHub ↗</a>
      </nav>
      <a href="mailto:geraldndyamukama39@gmail.com">Contact the project ↗</a>
      <span>
        © {new Date().getFullYear()}{" "}
        <a className="author-link" href={whatsappUrl}>
          Gerald Ndyamukama
        </a>
        . Third-party software retains its own licenses and credits.
      </span>
    </footer>
  );
}
