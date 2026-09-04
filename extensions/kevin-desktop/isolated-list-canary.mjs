import { listFolder, isSafeDesktopName } from "./dist/desktop.js";
import { readdir } from "node:fs/promises";
import { join } from "node:path";
import { createHash } from "node:crypto";

const neg = [];
for (const name of ["../secret", "..", "C:\\Windows", "foo/bar"]) {
  const r = await listFolder({ root: "Desktop", name });
  neg.push({ name, ok: r.ok, error: r.error });
}
const badRoot = await listFolder({ root: "C:\\Windows" });
neg.push({ root: "C:\\Windows", ok: badRoot.ok, error: badRoot.error });

const result = await listFolder({ root: "Desktop", limit: 50 });
const desktop = join(process.env.USERPROFILE, "Desktop");
let osNames = [];
try {
  osNames = (await readdir(desktop)).filter((n) => n !== "." && n !== "..");
} catch (e) {
  osNames = [`ERR:${e.message}`];
}
const listed = (result.entries || []).map((e) => e.name);
const overlap = listed.filter((n) => osNames.some((o) => o.toLowerCase() === n.toLowerCase()));
const leak = JSON.stringify(result).includes(desktop) || JSON.stringify(result).toLowerCase().includes(process.env.USERPROFILE.toLowerCase());

const out = {
  ok: result.ok,
  action: result.action,
  root: result.root,
  count: result.count,
  truncated: result.truncated,
  redacted: result.redacted,
  sample: listed.slice(0, 12),
  kinds: (result.entries || []).slice(0, 12).map((e) => e.kind),
  os_count: osNames.length,
  overlap_count: overlap.length,
  path_leak: leak,
  negatives: neg,
  all_neg_fail_closed: neg.every((n) => n.ok === false),
};
const hash = createHash("sha256").update(JSON.stringify(out)).digest("hex").toUpperCase();
out.proof_sha256 = hash;
console.log(JSON.stringify(out, null, 2));