import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export type CatalogControl = { id: string; name: string };

export type CalculatorCatalog = {
  app: string;
  version: number;
  controls: CatalogControl[];
};

const ROOT = dirname(fileURLToPath(import.meta.url));
const CATALOG_PATH = join(ROOT, "..", "calculator-catalog.v0.json");

let cachedIds: Set<string> | null = null;

export function loadCatalog(): CalculatorCatalog {
  const raw = readFileSync(CATALOG_PATH, "utf8");
  return JSON.parse(raw) as CalculatorCatalog;
}

export function catalogControlIds(): Set<string> {
  if (cachedIds) return cachedIds;
  const data = loadCatalog();
  cachedIds = new Set((data.controls ?? []).map((c) => c.id));
  return cachedIds;
}

/** Test helper: clear cached catalog ids. */
export function resetCatalogCache(): void {
  cachedIds = null;
}
