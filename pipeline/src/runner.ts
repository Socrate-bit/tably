import {join} from "node:path";
import {mapLimit} from "./ids.js";
import {PendingLLM} from "./llm.js";
import {saveMasterTable} from "./ingredients.js";
import {batchDir, hasStage, readJson, readStage, stageIds, writeJson, writeStage} from "./store.js";
import {balanceStage} from "./stages/balance.js";
import {checkStage} from "./stages/check.js";
import {cleanStage} from "./stages/clean.js";
import {dedupeStage} from "./stages/dedupe.js";
import {mapStage} from "./stages/map.js";
import {nutritionStage} from "./stages/nutrition.js";
import {photoStage} from "./stages/photo.js";
import {portionStage} from "./stages/portion.js";
import {priceStage} from "./stages/price.js";
import {tagStage} from "./stages/tag.js";
import {validateStage} from "./stages/validate.js";
import {variantsStage} from "./stages/variants.js";

export interface StageContext {
  batch: string;
  id: string;
}

export interface Stage<I = any, O = any> {
  name: string;
  /** Stage whose output is this stage's input. */
  prev: string;
  /** Per-recipe work. */
  run?(input: I, ctx: StageContext): Promise<O>;
  /** Whole-batch work (one Batch API job for every recipe); returns an output or an Error per id. */
  runAll?(inputs: {id: string; input: I}[], batch: string): Promise<Map<string, O | Error>>;
}

/** Pipeline order. `raw` is written by the seed command. Stages in the same inner array run concurrently. */
export const GROUPS: Stage[][] = [
  [cleanStage], [mapStage], [nutritionStage], [balanceStage], [portionStage], [tagStage], [priceStage],
  [checkStage, dedupeStage, photoStage],
  [variantsStage],
  [validateStage],
];
export const STAGES: Stage[] = GROUPS.flat();
export const STAGE_NAMES = STAGES.map((s) => s.name);

export interface RunOptions {
  batch: string;
  from?: string;
  to?: string;
  only?: string[];
  force?: boolean;
  limit?: number;
  concurrency?: number;
}

type ErrorLog = Record<string, {stage: string; message: string}>;

/**
 * Run the stages from..to over every recipe of the batch, one stage at a time
 * so that cross-recipe stages (dedupe) see the whole batch. Existing outputs
 * are skipped unless `force`; failures go to work/<batch>/errors.json.
 */
export async function runStages(opts: RunOptions): Promise<void> {
  const fromIdx = opts.from ? indexOf(opts.from) : 0;
  const toIdx = opts.to ? indexOf(opts.to) : STAGES.length - 1;
  if (fromIdx > toIdx) throw new Error(`--from ${opts.from} is after --to ${opts.to}`);
  const errorsPath = join(batchDir(opts.batch), "errors.json");
  const errors = readJson<ErrorLog>(errorsPath, {});
  const wanted = new Set(STAGES.slice(fromIdx, toIdx + 1).map((s) => s.name));

  for (const group of GROUPS) {
    const stages = group.filter((s) => wanted.has(s.name));
    if (!stages.length) continue;
    const results = await Promise.all(stages.map((stage) => runStage(stage, opts, errors)));
    writeJson(errorsPath, errors);
    if (results.some((waiting) => waiting)) return;
  }
}

/** Run one stage over the batch; returns true when it is waiting for LLM answers. */
async function runStage(stage: Stage, opts: RunOptions, errors: ErrorLog): Promise<boolean> {
  {
    let ids = stageIds(opts.batch, stage.prev);
    if (opts.only?.length) ids = ids.filter((id) => opts.only!.includes(id));
    if (opts.limit) ids = ids.slice(0, opts.limit);
    const counts = {done: 0, skipped: 0, rejected: 0, failed: 0, waiting: 0};
    const pendingPaths = new Set<string>();
    const started = Date.now();

    const record = (id: string, result: unknown) => {
      if (result instanceof PendingLLM) {
        counts.waiting++;
        pendingPaths.add(result.requestPath);
        delete errors[id];
      } else if (result instanceof Error) {
        counts.failed++;
        errors[id] = {stage: stage.name, message: result.message};
        console.error(`[runner] ${stage.name} ${id} failed: ${result.message}`);
      } else {
        writeStage(opts.batch, stage.name, id, result);
        delete errors[id];
        counts.done++;
        if ((result as any)?.review?.verdict === "reject" && stage.name === "check") counts.rejected++;
      }
    };
    // Inputs still to process: not done yet (unless --force) and not rejected upstream.
    const pending: {id: string; input: any}[] = [];
    for (const id of ids) {
      if (!opts.force && hasStage(opts.batch, stage.name, id)) {
        counts.skipped++;
        continue;
      }
      const input = readStage<any>(opts.batch, stage.prev, id);
      if (input?.rejected) counts.rejected++;
      else pending.push({id, input});
    }

    if (stage.runAll) {
      if (pending.length) {
        try {
          const results = await stage.runAll(pending, opts.batch);
          for (const {id} of pending) record(id, results.get(id) ?? new Error("no result from batch stage"));
        } catch (error) {
          for (const {id} of pending) record(id, error as Error);
        }
      }
    } else {
      await mapLimit(pending, opts.concurrency ?? 6, async ({id, input}) => {
        try {
          record(id, await stage.run!(input, {batch: opts.batch, id}));
        } catch (error) {
          record(id, error as Error);
        }
      });
    }

    // The map and balance stages may add pending master rows.
    saveMasterTable();
    const seconds = ((Date.now() - started) / 1000).toFixed(1);
    console.log(`[runner] ${stage.name}: ${counts.done} done, ${counts.skipped} skipped, ` +
      `${counts.rejected} rejected, ${counts.failed} failed, ${counts.waiting} waiting (${seconds}s)`);
    if (counts.waiting) {
      console.log(`[runner] ${stage.name} is waiting for LLM answers (${pendingPaths.size} requests in work/llm/requests).`);
      return true;
    }
    return false;
  }
}

function indexOf(name: string): number {
  const idx = STAGE_NAMES.indexOf(name);
  if (idx < 0) throw new Error(`Unknown stage "${name}". Stages: ${STAGE_NAMES.join(", ")}`);
  return idx;
}
