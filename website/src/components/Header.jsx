import { useState } from "react";
import { Link, NavLink } from "react-router-dom";
import { navigation } from "../data/navigation";
import Icon from "./Icon.jsx";
export default function Header() {
  const [open, setOpen] = useState(false);
  return (
    <header className="site-header">
      <div className="header-inner">
        <Link
          className="brand"
          to="/"
          aria-label="Kilimanjaro OS home"
          onClick={() => setOpen(false)}
        >
          <img src="/brand/kilimanjaro.svg" alt="" />
          <span>
            KILIMANJARO<span className="brand-os"> OS</span>
          </span>
        </Link>
        <button
          className="mobile-toggle icon-button"
          aria-expanded={open}
          aria-controls="navigation"
          aria-label={open ? "Close navigation" : "Open navigation"}
          onClick={() => setOpen(!open)}
        >
          <Icon name={open ? "close" : "menu"} />
        </button>
        <nav
          id="navigation"
          className={open ? "navigation open" : "navigation"}
          aria-label="Main navigation"
          onClick={() => setOpen(false)}
        >
          {navigation.map((item) => (
            <NavLink key={item.path} to={item.path} end>
              {item.label}
            </NavLink>
          ))}
          <NavLink className="nav-download" to="/downloads">
            Get Kilimanjaro <Icon name="download" size={16} />
          </NavLink>
        </nav>
      </div>
    </header>
  );
}
