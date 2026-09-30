import { useState } from "react";
import Icon from "../components/Icon";
import { wallpapers } from "../data/content";

export default function DesktopGallery() {
  const [selected, setSelected] = useState(0);
  return (
    <section className="desktop-section container section" id="desktop">
      <div className="section-heading">
        <div>
          <p className="eyebrow">FAMILIAR FEEL. FRESH OUTLOOK.</p>
          <h1 className="page-title">
            A place to
            <br />
            <span>make your own.</span>
          </h1>
        </div>
        <p>
          A calm, dark desktop. A mountain on your horizon. Eleven original
          wallpapers, one unmistakable identity.
        </p>
      </div>
      <div className="desktop-preview">
        <div className="preview-toolbar">
          <span>
            <i />
            <i />
            <i />
          </span>
          <span>Kilimanjaro wallpaper collection</span>
          <span>6 scenes</span>
        </div>
        <img
          src={`/wallpapers/${wallpapers[selected].id}.webp`}
          alt={`Kilimanjaro OS wallpaper: ${wallpapers[selected].name}`}
          loading="lazy"
        />
        <div className="preview-caption">
          <span>
            <Icon name="mountain" /> {wallpapers[selected].name}
          </span>
          <span>WALLPAPER PREVIEW · NOT A LIVE SESSION</span>
        </div>
      </div>
      <div
        className="wallpaper-picker"
        role="group"
        aria-label="Explore desktop wallpapers"
      >
        {wallpapers.map((item, index) => (
          <button
            key={item.id}
            aria-pressed={selected === index}
            className={selected === index ? "selected" : ""}
            onClick={() => setSelected(index)}
          >
            <img src={`/wallpapers/${item.id}.webp`} alt="" loading="lazy" />
            <span>{item.name}</span>
          </button>
        ))}
      </div>
    </section>
  );
}
