export default function GuideSection({ id, number, title, children }) {
  return (
    <section className="guide-section" id={id} aria-labelledby={`${id}-title`}>
      <p className="eyebrow">GUIDE / {number}</p>
      <h2 id={`${id}-title`}>{title}</h2>
      {children}
    </section>
  );
}
