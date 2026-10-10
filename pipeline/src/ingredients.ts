import {SUITABLE_KEYS} from "./config.js";
import {PATHS} from "./config.js";
import {ciqualFood} from "./ciqual.js";
import {type Allergen, type Macros, MasterIngredient, type Suitable} from "./schema.js";
import {readJson, writeJson} from "./store.js";
import {normaliseText, slugify} from "./text.js";

export type MasterTable = Record<string, MasterIngredient>;

let table: MasterTable | undefined;

/** data/ingredients.json, loaded once and mutated in place by the map stage. */
export function masterTable(): MasterTable {
  return (table ??= readJson<MasterTable>(PATHS.ingredients, {}));
}

export function saveMasterTable(): void {
  const sorted = Object.fromEntries(Object.entries(masterTable()).sort(([a], [b]) => a.localeCompare(b)));
  writeJson(PATHS.ingredients, sorted);
}

export function getIngredient(slug: string): MasterIngredient | undefined {
  return masterTable()[slug];
}

/** Add (or replace) a row; validates and normalises the slug. */
export function putIngredient(row: MasterIngredient): MasterIngredient {
  const clean = MasterIngredient.parse({...row, slug: slugify(row.slug || row.name.en)});
  masterTable()[clean.slug] = clean;
  return clean;
}

/**
 * Deterministic lookup: slug, then aliases / names (normalised), then a high
 * token overlap. Returns undefined when nothing is close enough.
 */
export function findIngredient(name: string): MasterIngredient | undefined {
  const rows = masterTable();
  const key = normaliseText(name);
  const slug = slugify(name);
  if (rows[slug]) return rows[slug];
  for (const row of Object.values(rows)) {
    if ([row.name.en, row.name.fr, ...row.aliases].some((n) => normaliseText(n) === key)) return row;
  }
  const query = new Set(key.split(" ").filter(Boolean));
  let best: {row: MasterIngredient; score: number} | undefined;
  for (const row of Object.values(rows)) {
    for (const candidate of [row.name.en, ...row.aliases]) {
      const tokens = new Set(normaliseText(candidate).split(" ").filter(Boolean));
      let inter = 0;
      for (const t of query) if (tokens.has(t)) inter++;
      const score = inter / (query.size + tokens.size - inter);
      if (score >= 0.8 && (!best || score > best.score)) best = {row, score};
    }
  }
  return best?.row;
}

/** Per-100 g nutrition of a row: CIQUAL when matched, else the LLM estimate, else null. */
export function per100g(row: MasterIngredient): Macros | null {
  return ciqualFood(row.ciqualCode)?.per100g ?? row.per100g;
}

/** Allergen that each `<x>_free` flag excludes. */
const ALLERGEN_OF: Partial<Record<(typeof SUITABLE_KEYS)[number], Allergen[]>> = {
  gluten_free: ["gluten"],
  lactose_free: ["milk"],
  nut_free: ["nuts", "peanuts"],
  egg_free: ["egg"],
  shellfish_free: ["shellfish", "molluscs"],
  sesame_free: ["sesame"],
  soy_free: ["soy"],
};

/** Diet and allergen flags computed from the master rows of a recipe. Optional lines count too. */
export function computeSuitable(rows: MasterIngredient[]): Suitable {
  const has = (test: (r: MasterIngredient) => boolean) => rows.some(test);
  const result = {} as Suitable;
  for (const key of SUITABLE_KEYS) {
    switch (key) {
      case "vegetarian": result[key] = !has((r) => r.flags.isMeat || r.flags.isFish); break;
      case "vegan": result[key] = !has((r) => r.flags.isAnimal || r.flags.isMeat || r.flags.isFish); break;
      case "pescatarian": result[key] = !has((r) => r.flags.isMeat); break;
      case "halal": result[key] = !has((r) => r.flags.isPork || r.flags.hasAlcohol); break;
      default: {
        const excluded = ALLERGEN_OF[key] ?? [];
        result[key] = !has((r) => r.allergens.some((a) => excluded.includes(a)));
      }
    }
  }
  return result;
}
