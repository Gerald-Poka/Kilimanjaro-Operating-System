import { useEffect, useRef } from "react";

// A small, cursor-responsive constellation tracing a mountain ridgeline.
export default function SummitField({ enabled }) {
  const canvasRef = useRef(null);
  useEffect(() => {
    if (!enabled || !window.matchMedia("(pointer: fine)").matches) return;
    const canvas = canvasRef.current;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const hero = canvas.parentElement;
    let width = 0,
      height = 0,
      frame = 0,
      visible = true;
    const pointer = { x: -1000, y: -1000 };
    const points = Array.from({ length: 42 }, (_, i) => ({
      seed: i,
      x: 0,
      y: 0,
    }));
    const resize = () => {
      width = hero.clientWidth;
      height = hero.clientHeight;
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    const move = (event) => {
      const rect = hero.getBoundingClientRect();
      pointer.x = event.clientX - rect.left;
      pointer.y = event.clientY - rect.top;
    };
    const leave = () => {
      pointer.x = -1000;
      pointer.y = -1000;
    };
    const draw = (time) => {
      ctx.clearRect(0, 0, width, height);
      points.forEach((point, i) => {
        const t = i / (points.length - 1);
        const baseX = width * (0.46 + t * 0.5);
        const baseY =
          height *
          (0.61 - Math.sin(t * Math.PI) * 0.24 + Math.sin(t * 24) * 0.025);
        const dx = baseX - pointer.x,
          dy = baseY - pointer.y;
        const distance = Math.hypot(dx, dy);
        const force = Math.max(0, 1 - distance / 180) * 38;
        point.x = baseX + (dx / Math.max(distance, 1)) * force;
        point.y =
          baseY +
          (dy / Math.max(distance, 1)) * force +
          Math.sin(time / 1800 + i) * 3;
        ctx.fillStyle =
          i % 6 === 0 ? "rgba(241,182,90,.65)" : "rgba(142,225,210,.4)";
        ctx.beginPath();
        ctx.arc(point.x, point.y, i % 6 === 0 ? 2 : 1, 0, Math.PI * 2);
        ctx.fill();
        if (i) {
          ctx.strokeStyle = "rgba(158,215,208,.12)";
          ctx.beginPath();
          ctx.moveTo(points[i - 1].x, points[i - 1].y);
          ctx.lineTo(point.x, point.y);
          ctx.stroke();
        }
      });
      if (visible) frame = requestAnimationFrame(draw);
    };
    const observer = new IntersectionObserver(([entry]) => {
      cancelAnimationFrame(frame);
      visible = entry.isIntersecting && !document.hidden;
      if (visible) frame = requestAnimationFrame(draw);
    });
    const visibility = () => {
      cancelAnimationFrame(frame);
      visible = !document.hidden && hero.getBoundingClientRect().bottom > 0;
      if (visible) frame = requestAnimationFrame(draw);
    };
    resize();
    observer.observe(hero);
    hero.addEventListener("pointermove", move);
    hero.addEventListener("pointerleave", leave);
    window.addEventListener("resize", resize);
    document.addEventListener("visibilitychange", visibility);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
      ctx.clearRect(0, 0, width, height);
      hero.removeEventListener("pointermove", move);
      hero.removeEventListener("pointerleave", leave);
      window.removeEventListener("resize", resize);
      document.removeEventListener("visibilitychange", visibility);
    };
  }, [enabled]);
  return <canvas ref={canvasRef} className="summit-field" aria-hidden="true" />;
}
