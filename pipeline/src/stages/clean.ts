import {z} from "zod";
import {MODELS} from "../config.js";
import {jsonCall} from "../llm.js";
import type {Stage} from "../runner.js";
import {CleanDoc, CleanLine, Lang} from "../schema.js";
import {type RawRecipe, summariseRaw} from "../spoonacular.js";
import {loadPrompt} from "../store.js";

/** work/<batch>/raw/<id>.json as written by the seed command. */
export interface RawDoc {
  id: string;
  sourceId: number;
  fetchedAt: string;
  raw: RawRecipe;
}

const CleanOut = z.object({
  rejected: z.string().nullable(),
  title: Lang,
  steps: z.array(Lang),
  lines: z.array(CleanLine),
  cleanNotes: z.array(z.string()),
});

/** LLM: check and complete the steps, tidy the ingredient list, normalise units, write fr + en. */
export const cleanStage: Stage<RawDoc, CleanDoc> = {
  name: "clean",
  prev: "raw",
  async run(input, ctx) {
    const out = await jsonCall({
      model: MODELS.strong,
      system: loadPrompt("clean"),
      input: summariseRaw(input.raw),
      schema: CleanOut,
      label: `clean ${ctx.id}`,
    });
    if (out.rejected) console.log(`[clean] ${ctx.id} rejected: ${out.rejected}`);
    return CleanDoc.parse({
      id: input.id,
      sourceId: input.sourceId,
      sourceUrl: input.raw.sourceUrl ?? null,
      sourceName: input.raw.sourceName ?? null,
      imageUrl: typeof input.raw.image === "string" ? input.raw.image : null,
      title: out.title,
      steps: out.steps,
      claimedServings: Math.max(1, Number(input.raw.servings) || 1),
      lines: out.lines,
      cleanNotes: out.cleanNotes,
      rejected: out.rejected,
    });
  },
};
