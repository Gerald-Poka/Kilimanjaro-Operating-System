import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { wallpapers } from "../data/content";
import useReducedMotion from "../hooks/useReducedMotion";
import SummitField from "../components/SummitField";
import Icon from "../components/Icon";
export default function Hero() {
  const [scene, setScene] = useState(0);
  const [paused, setPaused] = useState(false);
  const [visited, setVisited] = useState(() => new Set([0]));
  const reduced = useReducedMotion();
  const motion = !paused && !reduced;
  useEffect(() => {
    setVisited((previous) => new Set([...previous, scene]));
  }, [scene]);
  useEffect(() => {
    if (!motion) return;
    const interval = setInterval(() => {
      if (!document.hidden)
        setScene((value) => (value + 1) % wallpapers.length);
    }, 10000);
    return () => clearInterval(interval);
  }, [motion]);
  useEffect(() => {
    if (motion) {
      const next = new Image();
      next.src = `/wallpapers/${wallpapers[(scene + 1) % wallpapers.length].id}.webp`;
    }
  }, [scene, motion]);
  return (
    <section className="hero" id="home" aria-labelledby="hero-title">
      {wallpapers.map((wallpaper, index) => (
        <div
          key={wallpaper.id}
          className={`hero-scene ${scene === index ? "active" : ""}`}
          style={{
            backgroundImage:
              scene === index || visited.has(index)
                ? `url(/wallpapers/${wallpaper.id}.webp)`
                : undefined,
          }}
        />
      ))}
      <div className="hero-shade" />
      <SummitField enabled={motion} />
      <div className="hero-content container">
        <div className="eyebrow">
          <span className="tiny-line" /> ROOTED IN TANZANIA. BUILT FOR
          POSSIBILITY.
        </div>
        <h1 id="hero-title">
          Your world.
          <br />A new <span>perspective.</span>
        </h1>
        <p className="hero-description">
          Meet Kilimanjaro OS. A thoughtfully crafted Linux desktop for
          learning, working and creating—online or off.
        </p>
        <div className="hero-actions">
          <Link className="button primary" to="/downloads">
            Get Kilimanjaro OS <Icon name="arrow" size={19} />
          </Link>
          <Link className="button ghost" to="/desktop">
            <Icon name="play" size={17} /> Explore the desktop
          </Link>
        </div>
        <div className="hero-meta">
          <span>
            <span className="status-dot" /> 0.1.0 Development preview
          </span>
          <span>Debian base · KDE Plasma · amd64</span>
        </div>
      </div>
      <div className="hero-bottom container">
        <Link className="scroll-cue" to="/why-kilimanjaro">
          <span>THERE’S MORE TO DISCOVER</span>
          <span>↗</span>
        </Link>
        <div className="scene-controls">
          <div className="scene-label">
            <span>THE KILIMANJARO COLLECTION</span>
            <strong>{wallpapers[scene].name}</strong>
          </div>
          <div
            className="scene-dots"
            role="group"
            aria-label="Choose background wallpaper"
          >
            {wallpapers.map((item, index) => (
              <button
                key={item.id}
                className={scene === index ? "selected" : ""}
                aria-label={`Show ${item.name}`}
                aria-pressed={scene === index}
                onClick={() => setScene(index)}
              />
            ))}
          </div>
          <button
            className="icon-button motion-button"
            aria-label={
              motion ? "Pause background motion" : "Resume background motion"
            }
            aria-pressed={paused || reduced}
            disabled={reduced}
            title={
              reduced ? "Motion disabled by your system preference" : undefined
            }
            onClick={() => setPaused(!paused)}
          >
            <Icon name={motion ? "pause" : "play"} size={17} />
          </button>
        </div>
      </div>
    </section>
  );
}
