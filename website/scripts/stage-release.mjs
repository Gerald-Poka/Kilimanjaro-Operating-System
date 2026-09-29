import { constants, createReadStream } from "node:fs";
import { mkdir, readFile, copyFile, writeFile, access } from "node:fs/promises";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = fileURLToPath(new URL("../", import.meta.url));
const output = path.resolve(root, "../output");
const file = "kilimanjaro-os-0.1.0-amd64.iso";
const hash = createHash("sha256");
for await (const chunk of createReadStream(path.join(output, file)))
  hash.update(chunk);
const sha256 = hash.digest("hex");
const manifest = await readFile(path.join(output, "SHA256SUMS"), "utf8");
if (
  !manifest
    .split("\n")
    .some(
      (line) =>
        line.trim().split(/\s+/)[0] === sha256 &&
        line.trim().split(/\s+/)[1] === file,
    )
)
  throw new Error("ISO checksum does not match SHA256SUMS. Refusing to stage.");
await mkdir(path.join(root, "public/releases"), { recursive: true });
for (const name of [file, "SHA256SUMS"])
  await copyFile(
    path.join(output, name),
    path.join(root, "public/releases", name),
    constants.COPYFILE_FICLONE,
  );
let signed = false;
try {
  await access(path.join(output, `${file}.sig`));
  await access(path.join(output, "SHA256SUMS.sig"));
  // Presence is not signature verification; this preview intentionally stays unsigned.
  console.log(
    "Signature files exist. Verify their trusted fingerprint separately before enabling signed-release claims.",
  );
} catch {
  /* Development ISO is currently unsigned. */
}
await writeFile(
  path.join(root, "public/release.json"),
  JSON.stringify(
    {
      available: true,
      version: "0.1.0",
      file,
      sha256,
      signed,
      channel: "development",
    },
    null,
    2,
  ) + "\n",
);
console.log(
  "Staged checksummed development ISO for local downloads. Not a production-release approval.",
);
