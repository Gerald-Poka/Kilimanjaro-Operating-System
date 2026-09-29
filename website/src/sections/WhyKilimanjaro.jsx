import Icon from "../components/Icon";
import { Link } from "react-router-dom";
import { benefits } from "../data/why";
import "../styles/sections/why.css";

export default function WhyKilimanjaro() {
  return (
    <section className="section container why-section" id="why">
      <div className="section-heading why-heading">
        <div>
          <p className="eyebrow">WHY KILIMANJARO?</p>
          <h1 className="page-title">
            Play. Create.
            <br />
            <span>Get things done.</span>
          </h1>
        </div>
        <div className="why-intro">
          <p>
            For your next gaming session, your next big idea, and the tasks that
            fill your day. One KDE desktop, with the tools to build your own
            setup.
          </p>
          <div className="why-audiences">
            <span>Gaming</span>
            <span>Content creation</span>
            <span>Everyday life</span>
          </div>
        </div>
      </div>
      <div className="benefit-grid">
        {benefits.map((item) => (
          <article className={`benefit-card benefit-${item.id}`} key={item.id}>
            <div className="benefit-visual" aria-hidden="true">
              <span className="benefit-visual-label">{item.visualLabel}</span>
              <div className="benefit-orbit" />
              <Icon name={item.icon} size={92} />
              <span className="benefit-visual-detail">{item.visualDetail}</span>
            </div>
            <div className="benefit-body">
              <p className="benefit-label">
                <span>{item.number}</span>
                {item.label}
              </p>
              <h2>{item.title}</h2>
              <p className="benefit-description">{item.description}</p>
              <ul
                className="benefit-tools"
                aria-label={`${item.category} tools`}
              >
                {item.tools.map((tool) => (
                  <li key={tool}>{tool}</li>
                ))}
              </ul>
              <p className="benefit-status">
                <Icon name="check" size={15} />
                {item.status}
              </p>
              <Link
                to={`/explore?category=${item.category}`}
                className="benefit-link"
              >
                {item.link}
                <Icon name="arrow" size={17} />
              </Link>
            </div>
          </article>
        ))}
      </div>
      <div className="why-next-step">
        <div>
          <p className="eyebrow">ONE DESKTOP. YOUR WAY.</p>
          <h2>Make room for what you love.</h2>
          <p>
            Personalize KDE Plasma, choose your software profiles in Welcome,
            and explore Kilimanjaro in a VM before making the switch.
          </p>
        </div>
        <Link className="button primary" to="/downloads">
          Try the development preview <Icon name="arrow" size={18} />
        </Link>
      </div>
      <p className="why-qualification">
        Gaming and creator profiles require separate downloads. Game
        compatibility and performance depend on your hardware and the title;
        NVIDIA and hybrid-graphics qualification is still in progress. This is a
        development preview, not a production release.
      </p>
    </section>
  );
}
