import { mkdir, copyFile } from "node:fs/promises";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = fileURLToPath(new URL("../", import.meta.url));
const project = path.resolve(root, "..");
await mkdir(path.join(root, "public/wallpapers"), { recursive: true });
await mkdir(path.join(root, "public/brand"), { recursive: true });
const scenes = [
  ["Kilimanjaro", "sunset"],
  ["Kilimanjaro-Dawn", "dawn"],
  ["Kilimanjaro-Blue-Hour", "blue-hour"],
  ["Kilimanjaro-Green-Morning", "green-morning"],
  ["Kilimanjaro-Uhuru-Glacier", "glacier"],
  ["Kilimanjaro-Savanna-Gold", "savanna"],
];
for (const [source, name] of scenes) {
  execFileSync("magick", [
    path.join(
      project,
      "overlay/usr/share/wallpapers",
      source,
      "contents/images/3840x2160.png",
    ),
    "-resize",
    "1920x1080>",
    "-quality",
    "82",
    path.join(root, "public/wallpapers", `${name}.webp`),
  ]);
}
await copyFile(
  path.join(
    project,
    "overlay/usr/share/icons/hicolor/scalable/apps/kilimanjaro-logo.svg",
  ),
  path.join(root, "public/brand/kilimanjaro.svg"),
);
console.log(
  "Prepared six optimized wallpapers and the existing OS emblem. Original artwork is unchanged.",
);
