import {z} from "zod";
import {ciqualCandidates, ciqualFood} from "../ciqual.js";
import {AISLES, ALLERGENS, MODELS, UNITS} from "../config.js";
import {findIngredient, getIngredient, masterTable, putIngredient} from "../ingredients.js";
import {jsonCall, PendingLLM} from "../llm.js";
import {findPrice} from "../prices.js";
import {usdaNutrition, webPrice} from "../sources.js";
import type {Stage} from "../runner.js";
import {Aisle, Allergen, type CleanDoc, type CleanLine, IngredientFlags, Lang, Macros, type MappedDoc, type MappedLine,
  type MasterIngredient} from "../schema.js";
import {loadPrompt} from "../store.js";
import {normaliseText} from "../text.js";
import {toGrams} from "../units.js";

const ProposedRow = z.object({
  slug: z.string(),
  name: Lang,
  aliases: z.array(z.string()),
  icon: z.string(),
  aisle: Aisle,
  allergens: z.array(Allergen),
  flags: IngredientFlags,
  gramsPerUnit: z.array(z.object({unit: z.enum(UNITS), grams: z.number()})),
  densityGPerMl: z.number().nullable(),
  ciqualCode: z.string().nullable(),
  per100g: Macros,
  pricePerKg: z.number().nullable(),
});

const CiqualOut = z.object({code: z.string().nullable()});

/**
 * Second chance at a CIQUAL code, searching with the French name (the table is
 * French-first, so "cilantro" finds nothing but "coriandre fraîche" does).
 */
export async function fillCiqual(row: MasterIngredient): Promise<boolean> {
  const seen = new Set<string>();
  const candidates = [row.name.fr, row.name.en, ...row.aliases].flatMap((n, i) => ciqualCandidates(n, i === 0 ? 12 : 5))
    .filter((c) => !seen.has(c.code) && seen.add(c.code));
  if (!candidates.length) return false;
  const out = await jsonCall({
    model: MODELS.lite,
    system: loadPrompt("ciqual"),
    input: {ingredient: {slug: row.slug, name: row.name, aisle: row.aisle}, candidates},
    schema: CiqualOut,
    label: `ciqual ${row.slug}`,
  });
  if (!out.code || !candidates.some((c) => c.code === out.code)) return false;
  row.ciqualCode = out.code;
  return true;
}

const NutritionOut = z.object({per100g: Macros});

/** Ask for a textbook per-100 g estimate when CIQUAL has nothing close. */
export async function estimateNutrition(row: MasterIngredient): Promise<void> {
  const out = await jsonCall({
    model: MODELS.lite,
    system: "Give the typical nutrition per 100 g, as bought, of the grocery ingredient below (kcal, protein, carbs, fat, fiber, salt, sugars in grams). Use standard food-composition values.",
    input: {slug: row.slug, name: row.name, aisle: row.aisle},
    schema: NutritionOut,
    label: `nutrition ${row.slug}`,
  });
  row.per100g = out.per100g;
}

const RowCheck = z.object({slug: z.string(), ok: z.boolean(), fixes: z.array(z.string()), row: ProposedRow.nullable()});
const RowsCheck = z.object({rows: z.array(RowCheck)});
const VERIFY_CHUNK = 8;

/**
 * Second opinion from the strongest model on the new master rows (flags, allergens,
 * grams per unit, CIQUAL choice), several rows per call. Corrected rows are applied
 * and every checked row is approved. This replaces the human approval gate.
 */
export async function verifyPendingRows(): Promise<number> {
  const pending = Object.values(masterTable()).filter((r) => r.status === "pending");
  let corrected = 0;
  for (let i = 0; i < pending.length; i += VERIFY_CHUNK) {
    const chunk = pending.slice(i, i + VERIFY_CHUNK);
    const out = await jsonCall({
      model: MODELS.review,
      system: loadPrompt("verify-ingredient"),
      input: {
        rows: chunk.map((row) => ({
          row: {...row, gramsPerUnit: Object.entries(row.gramsPerUnit).map(([unit, grams]) => ({unit, grams}))},
          ciqual: row.ciqualCode ? {code: row.ciqualCode, ...ciqualFood(row.ciqualCode)} : null,
        })),
      },
      schema: RowsCheck,
      label: `verify ${chunk.map((r) => r.slug).join("+")}`,
    });
    for (const row of chunk) {
      const check = out.rows.find((c) => c.slug === row.slug);
      if (check && !check.ok && check.row) {
        const fixed = check.row;
        Object.assign(row, {
          name: fixed.name, aliases: [...new Set([...row.aliases, ...fixed.aliases])], icon: fixed.icon, aisle: fixed.aisle,
          allergens: fixed.allergens, flags: fixed.flags, densityGPerMl: fixed.densityGPerMl,
          gramsPerUnit: Object.fromEntries(fixed.gramsPerUnit.map((g) => [g.unit, g.grams])),
          ciqualCode: fixed.ciqualCode ?? row.ciqualCode,
        });
        corrected++;
        console.log(`[map] reviewer corrected ${row.slug}: ${check.fixes.join("; ")}`);
      }
      row.status = "approved";
    }
  }
  return corrected;
}

/** Web prices for rows that still only have an LLM estimate, several rows per research call. */
export async function pricePendingRows(): Promise<number> {
  const rows = Object.values(masterTable()).filter((r) => r.priceSource !== "csv" && r.priceSource !== "web");
  let found = 0;
  await Promise.all(rows.map(async (row) => {
    try {
      if (await webPrice(row)) found++;
    } catch (error) {
      if (error instanceof PendingLLM) throw error;
      console.warn(`[map] web price failed for ${row.slug}: ${(error as Error).message}`);
    }
  }));
  return found;
}

const MapOut = z.object({
  /** Slug of an existing row when one of the near matches is the same food. */
  existingSlug: z.string().nullable(),
  row: ProposedRow.nullable(),
});

/** Existing rows that share a word with the name, offered to the LLM as near matches. */
function nearMatches(name: string, limit = 6): {slug: string; en: string; fr: string}[] {
  const query = normaliseText(name).split(" ").filter((t) => t.length > 2);
  return Object.values(masterTable())
    .map((row) => ({row, hits: query.filter((t) => normaliseText(`${row.name.en} ${row.aliases.join(" ")}`).includes(t)).length}))
    .filter((m) => m.hits > 0)
    .sort((a, b) => b.hits - a.hits)
    .slice(0, limit)
    .map(({row}) => ({slug: row.slug, en: row.name.en, fr: row.name.fr}));
}

/** Ask the LLM for a master row for an unknown ingredient and store it as pending. */
async function proposeIngredient(line: CleanLine, label: string): Promise<MasterIngredient> {
  const out = await jsonCall({
    model: MODELS.strong,
    system: loadPrompt("map-ingredients"),
    input: {
      ingredient: {name: line.name, note: line.note, unitUsed: line.unit, original: line.original},
      nearMatches: nearMatches(line.name),
      ciqualCandidates: ciqualCandidates(line.name),
      enums: {aisles: AISLES, allergens: ALLERGENS, units: UNITS},
    },
    schema: MapOut,
    label: `map ${label} "${line.name}"`,
  });
  if (out.existingSlug) {
    const existing = getIngredient(out.existingSlug);
    if (existing) {
      // Remember the new spelling so the next recipe resolves deterministically.
      if (!existing.aliases.some((a) => normaliseText(a) === normaliseText(line.name))) existing.aliases.push(line.name);
      return existing;
    }
  }
  if (!out.row) throw new Error(`no master row proposed for "${line.name}"`);
  // Real French prices win over the LLM's estimate whenever the CSV knows the ingredient.
  const csvPrice = findPrice([out.row.name.en, out.row.name.fr, out.row.slug, line.name, ...out.row.aliases]);
  const row = putIngredient({
    ...out.row,
    gramsPerUnit: Object.fromEntries(out.row.gramsPerUnit.map((g) => [g.unit, g.grams])),
    pricePerKg: csvPrice?.pricePerKg ?? out.row.pricePerKg,
    priceSource: csvPrice ? "csv" : out.row.pricePerKg == null ? null : "llm_estimate",
    nutritionSource: null,
    status: "pending",
  });
  // Nutrition: CIQUAL (French name) → USDA → the LLM's own estimate. Verification and web
  // prices run later in batched passes (see verifyPendingRows / pricePendingRows).
  if (!row.ciqualCode && !(await fillCiqual(row))) await usdaNutrition(row);
  row.nutritionSource = row.ciqualCode ? "ciqual" : row.nutritionSource ?? "llm_estimate";
  console.log(`[map] new ingredient ${row.slug} (${label}) nutrition=${row.nutritionSource} price=${row.priceSource ?? "none"}`);
  return row;
}

/** Resolve every line to a master row and grams. Exported so balance can re-map a rewrite. */
export async function mapLines(doc: CleanDoc, label: string): Promise<MappedDoc> {
  const unmapped: string[] = [];
  const newIngredients: string[] = [];
  const lines: MappedLine[] = [];
  let pending: PendingLLM | undefined;
  for (const line of doc.lines) {
    let row = findIngredient(line.name);
    if (!row) {
      try {
        row = await proposeIngredient(line, label);
      } catch (error) {
        // files backend: queue every unresolved line of the recipe in one pass.
        if (error instanceof PendingLLM) {
          pending = error;
          continue;
        }
        throw error;
      }
      if (row.status === "pending") newIngredients.push(row.slug);
    }
    const grams = toGrams(line.amount, line.unit, row);
    if (!grams) unmapped.push(`${line.name}: no grams for unit "${line.unit}" on ${row.slug}`);
    // The "or Y" substitute is a master row too, so the app can show and price it.
    let alternativeId: string | null = null;
    if (line.alternative) {
      let alt = findIngredient(line.alternative);
      if (!alt) {
        try {
          alt = await proposeIngredient({...line, name: line.alternative, alternative: null, original: `alternative for ${line.name}`}, label);
        } catch (error) {
          if (!(error instanceof PendingLLM)) throw error;
          pending = error;
        }
      }
      alternativeId = alt?.slug ?? null;
    }
    lines.push({...line, ingredientId: row.slug, alternativeId, grams: grams?.grams ?? 0, gramsBasis: grams?.basis ?? "none"});
  }
  if (pending) throw pending;
  return {...doc, lines, unmapped, newIngredients, steps: doc.steps.map((s) => ({fr: tokenise(s.fr, lines), en: tokenise(s.en, lines)}))};
}

/** Replace `{ingredient name}` tokens by `{slug}` tokens; unknown tokens are left for validate to flag. */
export function tokenise(text: string, lines: MappedLine[]): string {
  return text.replace(/\{([^{}]+)\}/g, (whole, inner: string) => {
    const key = normaliseText(inner);
    const line = lines.find((l) => normaliseText(l.name) === key || l.ingredientId === inner) ??
      lines.find((l) => normaliseText(getIngredient(l.ingredientId)?.name.en ?? "") === key);
    return line ? `{${line.ingredientId}}` : whole;
  });
}

export const mapStage: Stage<CleanDoc, MappedDoc> = {
  name: "map",
  prev: "clean",
  async runAll(inputs) {
    // Phase 1: every recipe in parallel (new rows are proposed as they appear).
    const results = new Map<string, MappedDoc | Error>();
    let pending: PendingLLM | undefined;
    await Promise.all(inputs.map(async ({id, input}) => {
      try {
        results.set(id, await mapLines(input, id));
      } catch (error) {
        if (error instanceof PendingLLM) pending = error;
        results.set(id, error as Error);
      }
    }));
    if (pending) return results;
    // Phase 2 and 3: batched verification and web prices for the new rows, then re-map
    // (rows may have been corrected, so grams can change).
    try {
      await Promise.all([verifyPendingRows(), pricePendingRows()]);
    } catch (error) {
      if (error instanceof PendingLLM) {
        for (const {id} of inputs) results.set(id, error);
        return results;
      }
      throw error;
    }
    for (const {id, input} of inputs) if (!(results.get(id) instanceof Error)) results.set(id, await mapLines(input, id));
    return results;
  },
};
