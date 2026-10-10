import {readFileSync} from "node:fs";
import {join} from "node:path";
import {PATHS} from "./config.js";
import type {CiqualFood, Macros} from "./schema.js";
import {readJson, writeJson} from "./store.js";
import {normaliseText} from "./text.js";

/** CIQUAL constant codes → our macro keys (all per 100 g). */
const CONSTANTS: Record<string, keyof Macros> = {
  "328": "kcal", "25000": "protein", "31000": "carbs", "32000": "sugars",
  "34100": "fiber", "40000": "fat", "10004": "salt",
};

/** Parse a CIQUAL value: "12,3", "-", "traces", "< 2,2". */
function parseValue(raw: string): number {
  const text = raw.trim();
  if (!text || text === "-" || text === "traces") return 0;
  const bounded = text.match(/^<\s*([\d,.]+)$/);
  if (bounded) return Number(bounded[1].replace(",", ".")) / 2;
  const value = Number(text.replace(",", "."));
  return Number.isFinite(value) ? value : 0;
}

/** Decode one of the windows-1252 XML files and yield each <TAG> block's fields. */
function* blocks(path: string, tag: string): Generator<Record<string, string>> {
  const xml = new TextDecoder("windows-1252").decode(readFileSync(path));
  const block = new RegExp(`<${tag}>([\\s\\S]*?)</${tag}>`, "g");
  const field = /<(\w+)>\s*([\s\S]*?)\s*<\/\1>/g;
  for (const m of xml.matchAll(block)) {
    const fields: Record<string, string> = {};
    for (const f of m[1].matchAll(field)) fields[f[1]] = f[2];
    yield fields;
  }
}

/**
 * Convert the unzipped CIQUAL 2020 XML folder (alim_*.xml + compo_*.xml) into
 * data/ciqual.json: {alim_code: {name, per100g}}.
 */
export function importCiqual(dir: string): number {
  const foods: Record<string, CiqualFood> = {};
  for (const f of blocks(join(dir, "alim_2020_07_07.xml"), "ALIM")) {
    foods[f.alim_code] = {
      name: {fr: f.alim_nom_fr, en: f.alim_nom_eng},
      per100g: {kcal: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, salt: 0, sugars: 0},
    };
  }
  // Some foods lack the EU-regulation kcal (328); keep the Jones-factor kcal (333) as a fallback.
  const fallbackKcal: Record<string, number> = {};
  for (const c of blocks(join(dir, "compo_2020_07_07.xml"), "COMPO")) {
    const key = CONSTANTS[c.const_code];
    const food = foods[c.alim_code];
    if (!food) continue;
    if (key) food.per100g[key] = parseValue(c.teneur);
    else if (c.const_code === "333") fallbackKcal[c.alim_code] = parseValue(c.teneur);
  }
  // Last resort (raw onion and others have no energy at all): Atwater factors from the macros.
  for (const [code, food] of Object.entries(foods)) {
    const p = food.per100g;
    if (p.kcal === 0 && fallbackKcal[code]) p.kcal = fallbackKcal[code];
    if (p.kcal === 0) p.kcal = Math.round(4 * p.protein + 4 * p.carbs + 9 * p.fat + 2 * p.fiber);
  }
  writeJson(PATHS.ciqual, foods);
  return Object.keys(foods).length;
}

let cache: Record<string, CiqualFood> | undefined;
export function ciqualTable(): Record<string, CiqualFood> {
  return (cache ??= readJson<Record<string, CiqualFood>>(PATHS.ciqual, {}));
}

export function ciqualFood(code: string | null): CiqualFood | undefined {
  return code ? ciqualTable()[code] : undefined;
}

/** Top-N CIQUAL foods whose French or English name shares the most tokens with `name`. */
export function ciqualCandidates(name: string, limit = 10): {code: string; fr: string; en: string}[] {
  const query = new Set(normaliseText(name).split(" ").filter((t) => t.length > 2));
  if (query.size === 0) return [];
  const scored: {code: string; fr: string; en: string; score: number}[] = [];
  for (const [code, food] of Object.entries(ciqualTable())) {
    const tokens = new Set(normaliseText(`${food.name.en} ${food.name.fr}`).split(" "));
    let hits = 0;
    for (const t of query) if (tokens.has(t)) hits++;
    if (hits === 0) continue;
    // Prefer short names (generic foods) over long prepared-dish entries.
    scored.push({code, fr: food.name.fr, en: food.name.en, score: hits / query.size - tokens.size / 100});
  }
  return scored.sort((a, b) => b.score - a.score).slice(0, limit).map(({score: _s, ...rest}) => rest);
}
