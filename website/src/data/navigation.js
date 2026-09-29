export const navigation = [
  { path: "/", label: "Home", title: "A new perspective" },
  {
    path: "/why-kilimanjaro",
    label: "Why Kilimanjaro",
    title: "Why Kilimanjaro",
  },
  { path: "/explore", label: "Explore", title: "Explore software" },
  { path: "/desktop", label: "Desktop", title: "The desktop collection" },
  {
    path: "/getting-started",
    label: "Getting started",
    title: "Getting started",
  },
  { path: "/about", label: "About", title: "About the project" },
  { path: "/documentation", label: "Documentation", title: "Documentation" },
];

export const pageTitles = Object.fromEntries([
  ...navigation.map((item) => [item.path, item.title]),
  ["/downloads", "Downloads"],
  ["/legal", "Legal overview"],
  ["/release-status", "Release status"],
]);
