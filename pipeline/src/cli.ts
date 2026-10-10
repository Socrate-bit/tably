import {parseArgs} from "node:util";
import {importCiqual} from "./ciqual.js";
import {PATHS} from "./config.js";
import {recipeId} from "./ids.js";
import {findIngredient, masterTable, saveMasterTable} from "./ingredients.js";
import {priceTable} from "./prices.js";
import {proposeRules} from "./propose.js";
import {report} from "./report.js";
import {serveReview} from "./review.js";
import {runStages, STAGE_NAMES} from "./runner.js";
import {estimateNutrition, fillCiqual} from "./stages/map.js";
import {complexSearch} from "./spoonacular.js";
import {hasStage, readJson, writeJson, writeStage} from "./store.js";
import {pullIndex, upload} from "./upload.js";

const USAGE = `tably pipeline

  seed               --batch <id> [--limit 10] [--query q] [--cuisine c] [--diet d]
  run                --batch <id> [--from stage] [--to stage] [--stage s] [--only id,id] [--force] [--limit n]
  report             --batch <id>
  review             --batch <id> [--port 8787]   before/after web UI
  import-ciqual      --dir <unzipped XML folder>
  import-prices      merge data/ingredient_prices.csv into the master table
  review-ingredients [--approve slug,slug | --approve-all]
  fill-ciqual        retry the CIQUAL match for master rows without a code
  requests           list open LLM requests (files backend) by tier
  propose-rules      --batch <id>   cluster reviewer notes into rule proposals (for you to accept)
  pull-index
  upload             --batch <id> [--apply] [--include-review] [--allow-pending]

Stages: raw(seed) → ${STAGE_NAMES.join(" → ")}`;

const {values: args, positionals} = parseArgs({
  allowPositionals: true,
  options: {
    batch: {type: "string"}, limit: {type: "string"}, port: {type: "string"}, query: {type: "string"}, cuisine: {type: "string"},
    diet: {type: "string"}, from: {type: "string"}, to: {type: "string"}, stage: {type: "string"},
    only: {type: "string"}, force: {type: "boolean", default: false}, dir: {type: "string"}, approve: {type: "string"},
    "approve-all": {type: "boolean", default: false}, apply: {type: "boolean", default: false},
    "include-review": {type: "boolean", default: false}, "allow-pending": {type: "boolean", default: false},
  },
});

function need(name: "batch" | "dir"): string {
  const value = args[name];
  if (!value) throw new Error(`--${name} is required\n\n${USAGE}`);
  return value;
}

/** Fetch usable, not-yet-seen Spoonacular recipes into work/<batch>/raw. */
async function seed(): Promise<void> {
  const batch = need("batch");
  const limit = Number(args.limit ?? 10);
  const seen = readJson<Record<string, string>>(PATHS.seen, {});
  let added = 0;
  for (let page = 0; page < 3 && added < limit; page++) {
    const {results, remaining} = await complexSearch({
      query: args.query, cuisine: args.cuisine, diet: args.diet, number: Math.min(100, limit * 2), offset: page * limit * 2,
    });
    console.log(`[seed] page ${page + 1}: ${results.length} results (quota left: ${remaining ?? "?"})`);
    if (!results.length) break;
    for (const raw of results) {
      if (added >= limit) break;
      const id = recipeId(raw.id);
      if (seen[raw.id] || hasStage(batch, "raw", id)) continue;
      writeStage(batch, "raw", id, {id, sourceId: raw.id, fetchedAt: new Date().toISOString(), raw});
      seen[raw.id] = id;
      added++;
      console.log(`[seed] ${id} ← ${raw.id} ${raw.title}`);
    }
  }
  writeJson(PATHS.seen, seen);
  console.log(`[seed] ${added} recipes written to work/${batch}/raw`);
}

/** Merge €/kg from data/ingredient_prices.csv into the master table (by fr/en name or alias). */
function importPrices(): void {
  let matched = 0;
  const unmatched: string[] = [];
  for (const row of priceTable()) {
    const master = row.names.map((n) => findIngredient(n)).find(Boolean);
    if (!master) {
      unmatched.push(row.id);
      continue;
    }
    master.pricePerKg = row.pricePerKg;
    master.priceSource = "csv";
    matched++;
  }
  saveMasterTable();
  console.log(`[prices] ${priceTable().length} rows: ${matched} matched a master row, ${unmatched.length} without one (they are picked up when the map stage creates the row)`);
}

function reviewIngredients(): void {
  const table = masterTable();
  const approve = new Set(args["approve-all"] ? Object.keys(table) : (args.approve ?? "").split(",").filter(Boolean));
  for (const slug of approve) {
    if (!table[slug]) throw new Error(`unknown ingredient ${slug}`);
    table[slug].status = "approved";
  }
  if (approve.size) saveMasterTable();
  const pending = Object.values(table).filter((r) => r.status === "pending");
  console.log(`[ingredients] ${Object.keys(table).length} rows, ${approve.size} approved now, ${pending.length} pending`);
  for (const r of pending) console.log(`  ${r.slug.padEnd(28)} ${r.name.fr.padEnd(28)} ${r.aisle.padEnd(14)} ciqual=${r.ciqualCode ?? "—"} €/kg=${r.pricePerKg ?? "—"}`);
}

async function main(): Promise<void> {
  const command = positionals[0];
  switch (command) {
    case "seed": return seed();
    case "run": {
      const stage = args.stage;
      return runStages({
        batch: need("batch"), from: stage ?? args.from, to: stage ?? args.to, force: args.force,
        only: args.only?.split(",").filter(Boolean), limit: args.limit ? Number(args.limit) : undefined,
      });
    }
    case "report": return void console.log(report(need("batch")));
    case "review": return serveReview(need("batch"), Number(args.port ?? 8787));
    case "import-ciqual": return void console.log(`[ciqual] ${importCiqual(need("dir"))} foods written to data/ciqual.json`);
    case "import-prices": return importPrices();
    case "review-ingredients": return reviewIngredients();
    case "fill-ciqual": {
      const rows = Object.values(masterTable()).filter((r) => !r.ciqualCode);
      let filled = 0;
      let estimated = 0;
      for (const row of rows) {
        if (await fillCiqual(row)) filled++;
        else if (!row.per100g) {
          await estimateNutrition(row);
          estimated++;
        }
      }
      saveMasterTable();
      return void console.log(`[ciqual] ${filled}/${rows.length} rows matched, ${estimated} estimated per 100 g`);
    }
    case "propose-rules": return void console.log(await proposeRules(need("batch")));
    case "requests": {
      const {readdirSync, existsSync} = await import("node:fs");
      const dir = PATHS.llmRequests;
      const open = existsSync(dir) ? readdirSync(dir).filter((f) => f.endsWith(".json")).map((f) => readJson<any>(`${dir}/${f}`))
        .filter((r) => !existsSync(r.responsePath)) : [];
      for (const r of open) console.log(`${r.tier.padEnd(6)} ${r.kind.padEnd(4)} ${r.label}`);
      return void console.log(`[requests] ${open.length} open`);
    }
    case "pull-index": return void console.log(`[index] ${await pullIndex()} published recipes indexed`);
    case "upload": return upload({
      batch: need("batch"), apply: args.apply, includeReview: args["include-review"], allowPending: args["allow-pending"],
    });
    default:
      console.log(USAGE);
      if (command) process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(`[cli] ${(error as Error).message}`);
  process.exitCode = 1;
});
