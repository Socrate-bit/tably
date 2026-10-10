import {z} from "zod";
import {MODELS} from "../config.js";
import {getIngredient} from "../ingredients.js";
import {jsonCall} from "../llm.js";
import type {Stage} from "../runner.js";
import {type CheckedDoc, CleanLine, Lang, type PricedDoc, Review} from "../schema.js";
import {summariseRaw} from "../spoonacular.js";
import {loadPrompt, readStage} from "../store.js";
import {mapLines} from "./map.js";
import {computeNutrition} from "./nutrition.js";
import {portionDoc} from "./portion.js";
import {priceStage} from "./price.js";
import {tagStage} from "./tag.js";

const FixOut = z.object({
  lines: z.array(CleanLine),
  steps: z.array(Lang),
  applied: z.array(z.string()),
  skipped: z.array(z.string()),
});

/** One reviewer call over source → clean → final. */
async function review(doc: PricedDoc, ctx: {batch: string; id: string}, round: number): Promise<z.infer<typeof Review>> {
  const raw = readStage<any>(ctx.batch, "raw", ctx.id).raw;
  const clean = readStage<any>(ctx.batch, "clean", ctx.id);
  return jsonCall({
    model: MODELS.review,
    system: loadPrompt("check"),
    input: {
      source: summariseRaw(raw),
      afterClean: {title: clean.title, claimedServings: clean.claimedServings, lines: clean.lines.map((l: any) => `${l.amount} ${l.unit} ${l.name}`), steps: clean.steps.map((s: any) => s.en)},
      modifications: {clean: doc.cleanNotes, balance: doc.balance.changes, servings: `${doc.claimedServings} → ${doc.servings}`, tier: doc.tier},
      final: {
        title: doc.title,
        servings: doc.servings,
        tier: doc.tier,
        perPortion: doc.portion.macros,
        pricePerPortion: doc.pricePerPortion,
        tags: doc.tags,
        suitable: doc.suitable,
        ingredientsPerPortion: doc.portion.lines.map((l) => {
          const row = getIngredient(l.ingredientId);
          return {token: `{${l.ingredientId}}`, name: row?.name, amount: l.amount, unit: l.unit, grams: l.grams, note: l.note, optional: l.optional, flags: row?.flags, allergens: row?.allergens};
        }),
        steps: doc.steps,
      },
      pipelineNotes: doc.reviewNotes,
    },
    schema: Review,
    temperature: 0.1,
    label: `check ${ctx.id} #${round}`,
  });
}

/** Apply the reviewer's notes, then recompute map → nutrition → portion → tag → price. */
async function applyFixes(doc: PricedDoc, notes: string[], ctx: {batch: string; id: string}): Promise<{doc: PricedDoc; applied: string[]; skipped: string[]}> {
  const fix = await jsonCall({
    model: MODELS.strong,
    system: loadPrompt("fix"),
    input: {
      title: doc.title,
      claimedServings: doc.claimedServings,
      lines: doc.lines.map((l) => ({name: l.name, amount: l.amount, unit: l.unit, note: l.note, optional: l.optional, alternative: l.alternative, original: l.original})),
      steps: doc.steps.map((s) => ({
        // Steps carry slug tokens by now; show the names so the model can keep using names.
        fr: s.fr.replace(/\{([^{}]+)\}/g, (_, slug: string) => `{${doc.lines.find((l) => l.ingredientId === slug)?.name ?? slug}}`),
        en: s.en.replace(/\{([^{}]+)\}/g, (_, slug: string) => `{${doc.lines.find((l) => l.ingredientId === slug)?.name ?? slug}}`),
      })),
      cleanNotes: doc.cleanNotes,
      notes,
    },
    schema: FixOut,
    label: `fix ${ctx.id}`,
  });
  if (!fix.applied.length) return {doc, applied: [], skipped: fix.skipped};
  const remapped = await mapLines({...doc, lines: fix.lines, steps: fix.steps}, ctx.id);
  const nutrition = computeNutrition(remapped);
  const balanced = {...nutrition, balance: {...doc.balance, changes: [...doc.balance.changes, ...fix.applied.map((a) => `fix: ${a}`)]}, needsReview: doc.needsReview, reviewNotes: doc.reviewNotes};
  const portioned = portionDoc(balanced);
  const tagged = await tagStage.run!(portioned, ctx);
  const priced = await priceStage.run!(tagged, ctx);
  return {doc: priced, applied: fix.applied, skipped: fix.skipped};
}

/**
 * LLM reviewer (strongest model) with one fix loop: review → apply the actionable
 * notes → recompute → review again. The second verdict is final; a reject becomes a
 * draft with the notes attached.
 */
export const checkStage: Stage<PricedDoc, CheckedDoc> = {
  name: "check",
  prev: "price",
  async run(input, ctx) {
    const first = await review(input, ctx, 1);
    if (!first.notes.length) return {...input, review: first};
    const {doc, applied, skipped} = await applyFixes(input, first.notes, ctx);
    if (!applied.length) return {...input, review: {...first, notes: [...first.notes, ...skipped.map((s) => `not applied: ${s}`)]}};
    const second = await review(doc, ctx, 2);
    if (second.verdict === "reject") console.log(`[check] ${ctx.id} rejected after fixes: ${second.notes.join("; ")}`);
    return {
      ...doc,
      review: {...second, notes: [...second.notes, ...applied.map((a) => `applied: ${a}`), ...skipped.map((s) => `not applied: ${s}`)]},
    };
  },
};
