import { Link } from "react-router-dom";

export default function NotFoundPage() {
  return (
    <section className="section container">
      <p className="eyebrow">404 · OFF THE TRAIL</p>
      <h1 className="page-title">This page isn’t here.</h1>
      <p className="not-found-description">
        Head back to the summit and explore Kilimanjaro from there.
      </p>
      <Link to="/" className="button primary">
        Back to home
      </Link>
    </section>
  );
}
