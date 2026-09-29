// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Gerald Ndyamukama
import { copyFile, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

const website = fileURLToPath(new URL("../", import.meta.url));
await mkdir(path.join(website, "public"), { recursive: true });
for (const [source, target] of [
  ["LICENSE", "LICENSE.txt"],
  ["LICENSING.md", "licensing.txt"],
]) {
  await copyFile(
    path.join(website, "..", source),
    path.join(website, "public", target),
  );
}
