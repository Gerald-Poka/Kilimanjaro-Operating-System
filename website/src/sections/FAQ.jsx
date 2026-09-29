import { faqs } from "../data/content";

export default function FAQ() {
  return (
    <section className="container faq-section">
      <div className="faq-heading">
        <h3>A few things worth knowing.</h3>
        <span>HONEST ANSWERS, BEFORE YOU BEGIN.</span>
      </div>
      <div className="faq-list">
        {faqs.map(([question, answer]) => (
          <details key={question}>
            <summary>
              {question}
              <span>+</span>
            </summary>
            <p>{answer}</p>
          </details>
        ))}
      </div>
    </section>
  );
}
