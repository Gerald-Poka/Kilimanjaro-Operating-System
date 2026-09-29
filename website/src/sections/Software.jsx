import { useState } from "react";
import { useSearchParams } from "react-router-dom";
import { applications, categories } from "../data/content";
import Icon from "../components/Icon";
export default function Software() {
  const [searchParams, setSearchParams] = useSearchParams();
  const requestedCategory = searchParams.get("category");
  const category = categories.includes(requestedCategory)
    ? requestedCategory
    : categories[0];
  const [query, setQuery] = useState("");
  const filtered = applications.filter(
    (app) =>
      (query ? true : app.category === category) &&
      `${app.name} ${app.text} ${app.category}`
        .toLowerCase()
        .includes(query.toLowerCase()),
  );
  return (
    <section className="section container" id="software">
      <div className="section-heading">
        <div>
          <p className="eyebrow">A DESKTOP THAT FITS YOUR DAY</p>
          <h1 className="page-title">
            Less setup.
            <br />
            <span>More doing.</span>
          </h1>
        </div>
        <p>
          Start with the essentials. Add the tools that match your world through
          Kilimanjaro Welcome.
        </p>
      </div>
      <div className="software-toolbar">
        <div
          className="category-tabs"
          role="group"
          aria-label="Application categories"
        >
          {categories.map((item) => (
            <button
              key={item}
              className={category === item && !query ? "active" : ""}
              aria-pressed={category === item && !query}
              onClick={() => {
                setSearchParams({ category: item });
                setQuery("");
              }}
            >
              {item}
            </button>
          ))}
        </div>
        <label className="app-search">
          <Icon name="search" size={18} />
          <input
            aria-label="Search applications"
            placeholder="Find your tools"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
      </div>
      <div className="app-grid" aria-live="polite">
        {filtered.map((app) => (
          <article className="app-card" key={app.name}>
            <div className="app-icon">
              <Icon name={app.icon} size={26} />
            </div>
            <span
              className={`app-status ${app.status === "Included" ? "included" : ""}`}
            >
              {app.status}
            </span>
            <h3>{app.name}</h3>
            <p>{app.text}</p>
          </article>
        ))}
        {!filtered.length && (
          <p className="empty-state">
            No matching tools. Try “office”, “gaming” or “video”.
          </p>
        )}
      </div>
      <p className="fine-print">
        Optional profiles require downloads. Proprietary services have their own
        licenses and sign-in. Inclusion does not imply vendor endorsement.
      </p>
    </section>
  );
}
