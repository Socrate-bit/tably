import {z} from "zod";
import {MODELS, TIERS} from "../config.js";
import {jsonCall, PendingLLM} from "../llm.js";
import type {Stage} from "../runner.js";
import {type CheckedDoc, CleanLine, Lang} from "../schema.js";
import {hasStage, loadPrompt, writeStage} from "../store.js";
import {mapLines} from "./map.js";
import {computeNutrition} from "./nutrition.js";

const VariantOut = z.object({
  feasible: z.boolean(),
  reason: z.string().nullable(),
  title: Lang.nullable(),
  lines: z.array(CleanLine).nullable(),
  steps: z.array(Lang).nullable(),
  changes: z.array(z.string()),
});

/** Numeric definition of each tier the twin must meet to be kept (per 650/425 kcal portion). */
function qualifies(kcal: number, protein: number, veg: number, carbs: number, fatShare: number, tier: "light" | "regular"): string | null {
  const t = TIERS[tier];
  const issues: string[] = [];
  if (kcal < t.kcalMin - 30 || kcal > t.kcalMax + 30) issues.push(`${Math.round(kcal)} kcal`);
  if (protein < t.proteinMin - 2) issues.push(`protein ${protein.toFixed(0)} g`);
  if (veg < t.vegMin - 30) issues.push(`veg ${veg.toFixed(0)} g`);
  if (tier === "regular" && carbs < 25) issues.push(`carbs ${carbs.toFixed(0)} g`);
  if (tier === "light" && fatShare > 0.42) issues.push(`fat ${Math.round(fatShare * 100)}%`);
  return issues.length ? issues.join(", ") : null;
}

/**
 * Whole-batch stage: for every approved recipe that has no twin yet, derive the other
 * tier (regular ↔ light) with the LLM, verify the numbers in code, and inject the twin
 * as a new recipe at the `clean` stage of the same batch so it runs through the normal
 * chain (map → … → check → photo → final). Outputs a small record per parent.
 */
export const variantsStage: Stage<CheckedDoc, {id: string; twin: string | null; reason: string | null}> = {
  name: "variants",
  prev: "check",
  async runAll(inputs, batch) {
    const results = new Map<string, {id: string; twin: string | null; reason: string | null} | Error>();
    await Promise.all(inputs.map(async ({id, input}) => {
      try {
        if (input.variantOf || input.review.verdict !== "approve") {
          results.set(id, {id, twin: null, reason: input.variantOf ? "is itself a variant" : "parent not approved"});
          return;
        }
        const twinId = `${id}-${input.tier === "regular" ? "light" : "full"}`;
        if (hasStage(batch, "clean", twinId)) {
          results.set(id, {id, twin: twinId, reason: null});
          return;
        }
        const target = input.tier === "regular" ? "light" : "regular";
        const out = await jsonCall({
          model: MODELS.strong,
          system: loadPrompt("variant"),
          input: {
            tier: input.tier, target, title: input.title, claimedServings: input.claimedServings,
            perPortion: {...input.portion.macros, servings: input.servings},
            lines: input.lines.map((l) => ({name: l.name, amount: l.amount, unit: l.unit, note: l.note, optional: l.optional, alternative: l.alternative, original: l.original})),
            steps: input.steps.map((s) => ({
              fr: s.fr.replace(/\{([^{}]+)\}/g, (_, slug: string) => `{${input.lines.find((l) => l.ingredientId === slug)?.name ?? slug}}`),
              en: s.en.replace(/\{([^{}]+)\}/g, (_, slug: string) => `{${input.lines.find((l) => l.ingredientId === slug)?.name ?? slug}}`),
            })),
          },
          schema: VariantOut,
          label: `variant ${id}`,
        });
        if (!out.feasible || !out.lines || !out.steps || !out.title) {
          results.set(id, {id, twin: null, reason: out.reason ?? "not feasible"});
          return;
        }
        // Numbers decide: map + nutrition on the proposal, judged at the target tier's portion.
        const mapped = await mapLines({...input, id: twinId, variantOf: id, title: out.title, lines: out.lines, steps: out.steps, cleanNotes: [...input.cleanNotes, ...out.changes.map((c) => `variant: ${c}`)]}, twinId);
        const nutrition = computeNutrition(mapped);
        const n = Math.max(1, Math.round(nutrition.dish.kcal / TIERS[target].kcalTarget));
        const d = nutrition.dish;
        const problem = qualifies(d.kcal / n, d.protein / n, d.vegGrams / n, d.carbs / n, d.kcal ? (d.fat * 9) / d.kcal : 0, target);
        if (problem) {
          results.set(id, {id, twin: null, reason: `twin does not qualify as ${target}: ${problem}`});
          return;
        }
        writeStage(batch, "clean", twinId, {...mapped, lines: out.lines, steps: out.steps, rejected: null});
        console.log(`[variants] ${id} → ${twinId} (${target})`);
        results.set(id, {id, twin: twinId, reason: null});
      } catch (error) {
        results.set(id, error instanceof PendingLLM ? error : (error as Error));
      }
    }));
    return results;
  },
};
