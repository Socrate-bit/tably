import {z} from "zod";
import {MODELS, PATHS} from "../config.js";
import {jsonCall} from "../llm.js";
import type {Stage} from "../runner.js";
import {type DedupedDoc, type IndexEntry, type PricedDoc} from "../schema.js";
import {loadPrompt, readJson, readStage, stageIds} from "../store.js";
import {jaccard, titleKey} from "../text.js";

const JACCARD_MIN = 0.6;
/** Pantry lines every recipe has; they would inflate the similarity of unrelated dishes. */
const PANTRY = new Set(["salt", "pepper", "olive-oil", "vegetable-oil", "water", "butter", "sugar"]);
const MAX_CANDIDATES = 3;

const DedupeOut = z.object({same: z.boolean(), reason: z.string()});

export function indexEntry(doc: PricedDoc): IndexEntry {
  return {
    id: doc.id,
    sourceId: doc.sourceId,
    titleEn: doc.title.en,
    ingredientIds: [...new Set(doc.lines.filter((l) => l.grams > 0 && !PANTRY.has(l.ingredientId)).map((l) => l.ingredientId))],
    protein: doc.tags.protein,
  };
}

/** Published recipes (work/published-index.json, see `pull-index`) plus earlier recipes of this batch. */
function buildIndex(batch: string, id: string): IndexEntry[] {
  const published = readJson<IndexEntry[]>(PATHS.publishedIndex, []);
  const earlier = stageIds(batch, "price").filter((other) => other < id)
    .map((other) => indexEntry(readStage<PricedDoc>(batch, "price", other)));
  return [...published, ...earlier];
}

/** Exact source id, same normalised title, or a near-identical ingredient set confirmed by the LLM. */
export const dedupeStage: Stage<PricedDoc, DedupedDoc> = {
  name: "dedupe",
  prev: "price",
  async run(input, ctx) {
    const me = indexEntry(input);
    const myTitle = titleKey(me.titleEn);
    const candidates: DedupedDoc["dedupeCandidates"] = [];
    const parent = (input as any).variantOf as string | null | undefined;
    for (const other of buildIndex(ctx.batch, ctx.id)) {
      // A light/regular twin shares its parent's source; they are two versions, not duplicates.
      if (other.id === parent || other.id.startsWith(`${ctx.id}-`) || ctx.id.startsWith(`${other.id}-`)) continue;
      if (other.sourceId === me.sourceId) {
        candidates.push({id: other.id, reason: "sourceId", score: 1, confirmed: true});
        continue;
      }
      if (titleKey(other.titleEn) === myTitle) {
        candidates.push({id: other.id, reason: "title", score: 1, confirmed: false});
        continue;
      }
      const score = jaccard(me.ingredientIds, other.ingredientIds);
      if (score >= JACCARD_MIN && other.protein === me.protein) {
        candidates.push({id: other.id, reason: "jaccard", score, confirmed: false});
      }
    }
    candidates.sort((a, b) => b.score - a.score);
    const shortlist = candidates.slice(0, MAX_CANDIDATES);

    let duplicateOf: string | null = null;
    for (const candidate of shortlist) {
      if (!candidate.confirmed) {
        const other = buildIndex(ctx.batch, ctx.id).find((e) => e.id === candidate.id)!;
        const verdict = await jsonCall({
          model: MODELS.lite,
          system: loadPrompt("dedupe"),
          input: {
            a: {title: me.titleEn, ingredients: me.ingredientIds, protein: me.protein, firstSteps: input.steps.slice(0, 3).map((s) => s.en)},
            b: {title: other.titleEn, ingredients: other.ingredientIds, protein: other.protein},
          },
          schema: DedupeOut,
          label: `dedupe ${ctx.id}~${candidate.id}`,
        });
        candidate.confirmed = verdict.same;
      }
      if (candidate.confirmed && !duplicateOf) duplicateOf = candidate.id;
    }
    if (duplicateOf) console.log(`[dedupe] ${ctx.id} duplicates ${duplicateOf}`);
    return {...input, duplicateOf, dedupeCandidates: shortlist};
  },
};
