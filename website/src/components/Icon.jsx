const paths = {
  arrow: "M4 12h16m-6-6 6 6-6 6",
  download: "M12 3v12m-5-5 5 5 5-5M4 17v4h16v-4",
  mountain: "m2 19 7-12 4 6 3-4 6 10H2m5-8 2 2 2-2",
  signal: "M4 19v-4m5 4V11m5 8V7m5 12V3",
  book: "M12 5v16M3 3l9 2 9-2v16l-9 2-9-2V3",
  globe:
    "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0M3 12h18M12 3c-5 5-5 13 0 18 5-5 5-13 0-18",
  play: "m9 5 11 7-11 7V5",
  phone: "M7 2h10v20H7V2m3 17h4",
  file: "M5 2h9l5 5v15H5V2m9 0v6h5M8 12h8m-8 4h6",
  code: "m8 5-6 7 6 7m8-14 6 7-6 7M14 3l-4 18",
  spark: "m12 2 3 7 7 3-7 3-3 7-3-7-7-3 7-3 3-7",
  game: "M7 7h10c3 0 5 5 5 10 0 3-3 3-6-1H8c-3 4-6 4-6 1 0-5 2-10 5-10m-1 3v5m-2-2h5m7-2h.01m3 3h.01",
  record:
    "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0m-5 0a4 4 0 1 1-8 0 4 4 0 0 1 8 0",
  layers: "m2 8 10-6 10 6-10 6-10-6m0 5 10 6 10-6M2 18l10 6 10-6",
  users: "M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0M3 21v-3c0-6 18-6 18 0v3",
  music: "M9 18V5l11-3v14M9 18c0 4-6 4-6 0s6-4 6 0m11-2c0 4-6 4-6 0s6-4 6 0",
  check: "m5 12 4 4L19 6",
  pause: "M8 5v14m8-14v14",
  menu: "M3 6h18M3 12h18M3 18h18",
  close: "m5 5 14 14M19 5 5 19",
  search: "M16 10a6 6 0 1 1-12 0 6 6 0 0 1 12 0m-2 4 6 6",
  shield: "m12 2 9 4v7c0 5-9 9-9 9s-9-4-9-9V6l9-4m-4 10 3 3 5-6",
};
export default function Icon({ name, size = 22, ...props }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      <path d={paths[name] || paths.mountain} />
    </svg>
  );
}
