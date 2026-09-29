import Icon from "../components/Icon";
import { whatsappUrl } from "../data/contact";

export default function AboutIntro() {
  return (
    <section className="about-section container" id="about">
      <div className="about-emblem">
        <img src="/brand/kilimanjaro.svg" alt="Kilimanjaro mountain emblem" />
      </div>
      <div>
        <p className="eyebrow">INDEPENDENT PROJECT. SHARED HORIZON.</p>
        <h1 className="page-title">
          Built with purpose.
          <br />
          <span>
            By{" "}
            <a className="author-link" href={whatsappUrl}>
              Gerald Ndyamukama
            </a>
            .
          </span>
        </h1>
        <p>
          Kilimanjaro OS began with a simple ambition: make a useful, accessible
          desktop for the places we call home. The blueprint prioritizes offline
          access, bando preservation and a path toward Kiswahili-first
          computing.
        </p>
        <a href="mailto:geraldndyamukama39@gmail.com">
          Let’s talk about Kilimanjaro <Icon name="arrow" size={18} />
        </a>
      </div>
    </section>
  );
}
