import {z} from "zod";
import {PIPELINE_VERSION} from "../config.js";
import type {Stage} from "../runner.js";
import {type CheckedDoc, type DedupedDoc, type PhotoDoc, RecipeDoc} from "../schema.js";
import {readStage, stageIds} from "../store.js";

/** The final doc merges three concurrent stages: check (content after fixes), dedupe, photo. */
type MergedDoc = CheckedDoc & Pick<DedupedDoc, "duplicateOf" | "dedupeCandidates"> & Pick<PhotoDoc, "photo"> & {variantId?: string | null};

/** Build the final Firestore document and validate it. Photo paths are local until upload. */
export function toRecipeDoc(doc: MergedDoc): RecipeDoc {
  const now = new Date().toISOString();
  const draft = doc.needsReview || doc.duplicateOf !== null || doc.review.verdict === "reject";
  const candidate = {
    id: doc.id,
    status: draft ? "draft" : "published",
    variantOf: doc.variantOf ?? null,
    variantId: doc.variantId ?? null,
    sourceId: doc.sourceId,
    sourceUrl: doc.sourceUrl,
    sourceName: doc.sourceName,
    title: doc.title,
    steps: doc.steps,
    servings: doc.servings,
    totalMinutes: doc.tags.totalMinutes,
    activeMinutes: doc.tags.activeMinutes,
    difficulty: doc.tags.difficulty,
    tier: doc.tier,
    ingredients: doc.portion.lines.map((l) => ({
      ingredientId: l.ingredientId, alternativeId: l.alternativeId, amount: l.amount, unit: l.unit, grams: l.grams, note: l.note, optional: l.optional,
    })),
    macros: doc.portion.macros,
    craving: doc.tags.craving,
    cravings: doc.tags.cravings,
    protein: doc.tags.protein,
    cuisine: doc.tags.cuisine,
    cuisines: doc.tags.cuisines,
    appliances: doc.tags.appliances,
    suitable: doc.suitable,
    pricePerPortion: doc.pricePerPortion,
    reviewScore: doc.review.score,
    photo: {hero: doc.photo.heroPath, thumb: doc.photo.thumbPath, blurhash: doc.photo.blurhash},
    rand: Math.random(),
    keywords: doc.tags.keywords,
    createdAt: now,
    updatedAt: now,
    pipelineVersion: PIPELINE_VERSION,
    needsReview: doc.needsReview,
    reviewNotes: [
      ...doc.reviewNotes,
      ...(doc.duplicateOf ? [`duplicate of ${doc.duplicateOf}`] : []),
      ...(doc.review.verdict === "reject" ? doc.review.notes.map((n) => `reviewer: ${n}`) : []),
    ],
  };
  const result = RecipeDoc.safeParse(candidate);
  if (!result.success) throw new Error(`invalid recipe doc: ${z.prettifyError(result.error)}`);
  const recipe = result.data;

  // Rules zod cannot express.
  const problems: string[] = [];
  for (const i of recipe.ingredients) {
    if (i.unit !== "to_taste" && i.unit !== "pinch" && i.amount <= 0) problems.push(`${i.ingredientId}: amount ${i.amount}`);
  }
  for (const [index, step] of recipe.steps.entries()) {
    if (!step.fr.trim() || !step.en.trim()) problems.push(`step ${index + 1} missing a language`);
  }
  if (!recipe.title.fr.trim() || !recipe.title.en.trim()) problems.push("title missing a language");
  // Every {token} in a step must name an ingredient of the recipe; no quantities may remain in the text.
  const slugs = new Set(recipe.ingredients.map((i) => i.ingredientId));
  for (const [index, step] of recipe.steps.entries()) {
    for (const text of [step.fr, step.en]) {
      for (const m of text.matchAll(/\{([^{}]+)\}/g)) if (!slugs.has(m[1])) problems.push(`step ${index + 1}: unknown token {${m[1]}}`);
      if (/\b\d+([.,]\d+)?\s?(g|kg|ml|cl|l|tbsp|tsp)\b|\d\s?c\. à/i.test(text)) problems.push(`step ${index + 1}: quantity left in text`);
    }
  }
  if (recipe.pricePerPortion <= 0 && doc.unpriced.length === 0) problems.push("price is 0 with every ingredient priced");
  if (problems.length) throw new Error(`invalid recipe doc: ${problems.join("; ")}`);
  return recipe;
}

export const validateStage: Stage<PhotoDoc, RecipeDoc> = {
  name: "final",
  prev: "photo",
  async run(photo, ctx) {
    const checked = readStage<CheckedDoc>(ctx.batch, "check", ctx.id);
    const deduped = readStage<DedupedDoc>(ctx.batch, "dedupe", ctx.id);
    // The twin created by the variants stage (if any) points back here; record the link both ways.
    const twin = stageIds(ctx.batch, "check").map((id) => readStage<CheckedDoc>(ctx.batch, "check", id)).find((d) => d.variantOf === ctx.id);
    return toRecipeDoc({...checked, duplicateOf: deduped.duplicateOf, dedupeCandidates: deduped.dedupeCandidates, photo: photo.photo, variantId: twin?.id ?? null});
  },
};
