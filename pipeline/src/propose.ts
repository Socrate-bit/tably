import {readdirSync} from "node:fs";
import {join} from "node:path";
import {z} from "zod";
import {MODELS, PATHS} from "./config.js";
import {jsonCall} from "./llm.js";
import type {CheckedDoc} from "./schema.js";
import {batchDir, loadPrompt, readStage, stageIds, writeJson} from "./store.js";
import {writeFileSync} from "node:fs";

const Proposal = z.object({
  pattern: z.string(),
  occurrences: z.number(),
  recipeIds: z.array(z.string()),
  target: z.enum(["code", "data", "prompt", "enum", "policy"]),
  /** For prompt targets: the file name; for code/data: where. */
  where: z.string(),
  change: z.string(),
  risk: z.enum(["low", "medium", "high"]),
});
const Proposals = z.object({summary: z.string(), proposals: z.array(Proposal)});

/** Existing deterministic rules, so the model does not propose them again. */
const CODE_RULES = [
  "meat/fish ≥ 120 g raw per portion (portion stage scales it)",
  "kcal bands: light 350–500, regular 550–800; tier = light only when a 650 kcal plate would exceed 600 g",
  "floors: protein ≥ 25 g (light 20), vegetables ≥ 150 g (light 200), carbs ≥ 30 g for regular; fat soft",
  "cravings guards: quick ≤ 25 min, high_protein ≥ 30 g, low_calorie ≤ 500 kcal, healthy_comfort fat ≤ 40 %",
  "halal = no pork and no alcohol; diet/allergen flags computed from ingredient rows, LLM may only switch off",
  "every {token} in steps must name an ingredient of the recipe; no numeric quantities in step text",
  "per-portion amounts stored exact; rounding happens at display time",
];

/**
 * Cluster the reviewer notes of a batch into rule proposals for a human to accept.
 * Writes work/<batch>/rule-proposals.md and returns the markdown.
 */
export async function proposeRules(batch: string): Promise<string> {
  const recipes = stageIds(batch, "check").map((id) => {
    const d = readStage<CheckedDoc>(batch, "check", id);
    return {id, title: d.title.en, verdict: d.review.verdict, score: d.review.score, notes: d.review.notes, balanceChanges: d.balance.changes, warnings: d.reviewNotes};
  });
  const out = await jsonCall({
    model: MODELS.review,
    system: loadPrompt("propose-rules"),
    input: {recipes, promptFiles: readdirSync(PATHS.prompts), existingCodeRules: CODE_RULES},
    schema: Proposals,
    temperature: 0.1,
    label: `propose-rules ${batch}`,
  });
  const lines = [`# Rule proposals — batch ${batch} (${recipes.length} reviewed recipes)`, "", out.summary, ""];
  out.proposals.forEach((p, i) => {
    lines.push(`## ${i + 1}. ${p.pattern}`, "",
      `- occurrences: ${p.occurrences} (${p.recipeIds.join(", ")})`,
      `- target: **${p.target}** — ${p.where}`,
      `- risk: ${p.risk}`, "",
      p.change, "");
  });
  const md = lines.join("\n");
  writeFileSync(join(batchDir(batch), "rule-proposals.md"), md);
  writeJson(join(batchDir(batch), "rule-proposals.json"), out);
  return md;
}
