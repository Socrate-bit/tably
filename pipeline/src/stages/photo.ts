import {encode} from "blurhash";
import {mkdirSync, readFileSync, writeFileSync} from "node:fs";
import {join} from "node:path";
import sharp from "sharp";
import {z} from "zod";
import {env, MODELS} from "../config.js";
import {getIngredient} from "../ingredients.js";
import {type ImageInput, imageBatch, imageCall, jsonCall} from "../llm.js";
import type {Stage} from "../runner.js";
import type {PhotoDoc, PricedDoc} from "../schema.js";
import {batchDir, fillTemplate, loadPrompt, readJson, writeJson} from "../store.js";

const MAX_ROUNDS = 3;
// Square, as the prompt asks for 1:1.
const HERO = 1024;
const THUMB = 400;

const CheckOut = z.object({ok: z.boolean(), issues: z.array(z.string())});

/** Per-recipe state carried across rounds. */
interface Candidate {
  id: string;
  input: PricedDoc;
  dir: string;
  basePrompt: string;
  checkPrompt: string;
  prompt: string;
  image?: ImageInput;
  verified: boolean;
  attempts: number;
  error?: Error;
}

/** Persisted Batch API job names, so an interrupted wait can resume instead of paying again. */
type Jobs = Record<string, {jobName: string; ids: string[]}>;

/** Facts injected into the prompt templates. */
function facts(doc: PricedDoc): Record<string, string> {
  const ingredients = doc.portion.lines
    .filter((l) => !l.optional)
    .map((l) => getIngredient(l.ingredientId)?.name.en ?? l.name);
  return {
    title: doc.title.en,
    cuisine: doc.tags.cuisine.replace(/_/g, " "),
    ingredients: [...new Set(ingredients)].join(", "),
    steps: doc.steps.map((s) => s.en.replace(/\{([^{}]+)\}/g, (_, slug: string) => getIngredient(slug)?.name.en ?? slug)).join(" "),
  };
}

/** Encode a blurhash (4×4 components) from a small raw RGBA render. */
async function blurhashOf(image: Buffer): Promise<string> {
  const {data, info} = await sharp(image).resize(32, 32, {fit: "fill"}).ensureAlpha().raw().toBuffer({resolveWithObject: true});
  return encode(new Uint8ClampedArray(data), info.width, info.height, 4, 4);
}

/** Generate this round's images: one Batch API job for everyone, or live calls. */
async function generate(round: number, todo: Candidate[], jobsPath: string): Promise<void> {
  const prompts = todo.map((c) => c.prompt);
  const label = `photos round ${round}`;
  let outcomes: (ImageInput | Error)[];
  if (env.photoMode === "live") {
    outcomes = await Promise.all(prompts.map((p, i) => imageCall(p, `photo ${todo[i].id} #${round}`).catch((e: Error) => e)));
  } else {
    const jobs = readJson<Jobs>(jobsPath, {});
    const key = String(round);
    const existing = jobs[key]?.ids.join(",") === todo.map((c) => c.id).join(",") ? jobs[key].jobName : undefined;
    outcomes = await imageBatch(prompts, {
      label,
      existingJob: existing,
      onCreated: (jobName) => writeJson(jobsPath, {...readJson<Jobs>(jobsPath, {}), [key]: {jobName, ids: todo.map((c) => c.id)}}),
    });
  }
  todo.forEach((c, i) => {
    const outcome = outcomes[i];
    c.attempts++;
    if (outcome instanceof Error) {
      c.error = outcome;
      return;
    }
    c.error = undefined;
    c.image = outcome;
    writeFileSync(join(c.dir, `attempt-${c.attempts}.jpg`), outcome.data);
  });
}

/** Gemini vision check; rejected candidates get the issues appended to their prompt for the next round. */
async function verify(c: Candidate, round: number): Promise<void> {
  if (!c.image) return;
  const check = await jsonCall({
    model: MODELS.lite,
    system: c.checkPrompt,
    input: "Check this photo against the checklist.",
    images: [c.image],
    schema: CheckOut,
    label: `photo-check ${c.id} #${round}`,
  });
  c.verified = check.ok;
  if (!check.ok) {
    console.log(`[photo] ${c.id} round ${round} rejected: ${check.issues.join("; ")}`);
    c.prompt = `${c.basePrompt}\n\nAvoid these problems seen in a previous attempt: ${check.issues.join("; ")}.`;
  }
}

async function finish(c: Candidate): Promise<PhotoDoc> {
  const heroPath = join(c.dir, "hero.jpg");
  const thumbPath = join(c.dir, "thumb.jpg");
  await sharp(c.image!.data).resize(HERO, HERO, {fit: "cover"}).jpeg({quality: 85}).toFile(heroPath);
  await sharp(c.image!.data).resize(THUMB, THUMB, {fit: "cover"}).jpeg({quality: 80}).toFile(thumbPath);
  const blurhash = await blurhashOf(readFileSync(thumbPath));
  const reviewNotes = [...c.input.reviewNotes];
  if (!c.verified) reviewNotes.push(`photo not verified after ${c.attempts} attempts`);
  return {
    ...c.input,
    photo: {heroPath, thumbPath, blurhash, attempts: c.attempts, verified: c.verified},
    reviewNotes,
    needsReview: reviewNotes.length > 0,
  };
}

/**
 * Whole-batch stage: each round sends every unverified recipe to the image
 * model in one Batch API job, checks the results with Gemini vision, and
 * re-queues the rejected ones with feedback (≤ 3 rounds). Then derives sizes.
 */
export const photoStage: Stage<PricedDoc, PhotoDoc> = {
  name: "photo",
  prev: "price",
  async runAll(inputs, batch) {
    const photosDir = join(batchDir(batch), "photos");
    const jobsPath = join(photosDir, "jobs.json");
    const candidates: Candidate[] = inputs.map(({id, input}) => {
      const values = facts(input);
      const dir = join(photosDir, id);
      mkdirSync(dir, {recursive: true});
      const basePrompt = fillTemplate(loadPrompt("photo"), values);
      return {id, input, dir, basePrompt, prompt: basePrompt, checkPrompt: fillTemplate(loadPrompt("photo-check"), values), verified: false, attempts: 0};
    });

    for (let round = 1; round <= MAX_ROUNDS; round++) {
      const todo = candidates.filter((c) => !c.verified);
      if (!todo.length) break;
      console.log(`[photo] round ${round}: ${todo.length} images (${env.photoMode})`);
      await generate(round, todo, jobsPath);
      for (const c of todo) if (c.image && !c.error) await verify(c, round);
    }

    const results = new Map<string, PhotoDoc | Error>();
    for (const c of candidates) {
      results.set(c.id, c.image ? await finish(c) : (c.error ?? new Error("no image generated")));
    }
    return results;
  },
};
