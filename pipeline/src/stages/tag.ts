import {z} from "zod";
import {MODELS, SUITABLE_KEYS} from "../config.js";
import {computeSuitable, getIngredient} from "../ingredients.js";
import {jsonCall} from "../llm.js";
import type {Stage} from "../runner.js";
import {type MasterIngredient, type PortionedDoc, SuitableOverride, type TaggedDoc, Tags} from "../schema.js";
import {loadPrompt} from "../store.js";
import {keywordsOf} from "../text.js";

const TagOut = Tags.extend({suitableOverrides: z.array(SuitableOverride)});

/** Numeric craving definitions the LLM must respect; secondary cravings that fail are dropped silently. */
function cravingProblemFor(doc: PortionedDoc, tags: Tags, craving: string): string | null {
  if (craving === "quick" && tags.totalMinutes > 25) return `craving quick but ${tags.totalMinutes} min`;
  if (craving === "high_protein" && doc.portion.macros.protein < 30) return `craving high_protein but ${doc.portion.macros.protein} g`;
  if (craving === "low_calorie" && doc.portion.macros.kcal > 500) return `craving low_calorie but ${doc.portion.macros.kcal} kcal`;
  const fatShare = doc.portion.macros.kcal ? (doc.portion.macros.fat * 9) / doc.portion.macros.kcal : 0;
  if (craving === "healthy_comfort" && fatShare > 0.4) return `craving healthy_comfort but fat ${Math.round(fatShare * 100)}% of kcal`;
  return null;
}
const cravingProblem = (doc: PortionedDoc, tags: Tags): string | null => cravingProblemFor(doc, tags, tags.craving);

/** LLM tags + computed diet/allergen flags (LLM may only turn a flag off, with a reason). */
export const tagStage: Stage<PortionedDoc, TaggedDoc> = {
  name: "tag",
  prev: "portion",
  async run(input, ctx) {
    const rows = input.lines.map((l) => getIngredient(l.ingredientId)).filter((r): r is MasterIngredient => !!r);
    const suitable = computeSuitable(rows);
    const out = await jsonCall({
      model: MODELS.lite,
      system: loadPrompt("tag"),
      input: {
        title: input.title,
        tier: input.tier,
        servings: input.servings,
        perPortion: input.portion.macros,
        ingredients: input.portion.lines.map((l) => {
          const row = getIngredient(l.ingredientId);
          return {slug: l.ingredientId, name: l.name, amount: l.amount, unit: l.unit, grams: l.grams, flags: row?.flags, allergens: row?.allergens};
        }),
        steps: input.steps.map((s) => s.en),
        computedSuitable: suitable,
      },
      schema: TagOut,
      label: `tag ${ctx.id}`,
    });

    const reviewNotes = [...input.reviewNotes];
    const overrides = out.suitableOverrides.filter((o) => SUITABLE_KEYS.includes(o.flag) && suitable[o.flag]);
    for (const o of overrides) suitable[o.flag] = false;
    const problem = cravingProblem(input, out);
    if (problem) reviewNotes.push(problem);
    if (out.activeMinutes > out.totalMinutes) out.activeMinutes = out.totalMinutes;

    const {suitableOverrides: _o, ...tags} = out;
    // Primary values always belong to their lists.
    if (!tags.cravings.includes(tags.craving)) tags.cravings.unshift(tags.craving);
    if (!tags.cuisines.includes(tags.cuisine)) tags.cuisines.unshift(tags.cuisine);
    tags.cravings = tags.cravings.filter((c) => !cravingProblemFor(input, tags, c));
    if (!tags.cravings.length) tags.cravings = [tags.craving];
    if (!tags.cravings.includes(tags.craving)) tags.craving = tags.cravings[0];
    // Only the heaviest ingredients make it into the keywords; spices and oil would just add noise.
    const names = [...input.lines].sort((a, b) => b.grams - a.grams).slice(0, 5).flatMap((l) => {
      const row = getIngredient(l.ingredientId);
      return row ? [row.name.en, row.name.fr] : [l.name];
    });
    tags.keywords = keywordsOf(input.title.en, input.title.fr, ...tags.cuisines.map((c) => c.replace(/_/g, " ")), ...names, ...tags.keywords);
    return {...input, tags, suitable, suitableOverrides: overrides, reviewNotes, needsReview: reviewNotes.length > 0};
  },
};
