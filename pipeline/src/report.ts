import {join} from "node:path";
import {masterTable} from "./ingredients.js";
import {STAGE_NAMES} from "./runner.js";
import {batchDir, hasStage, readJson, readStage, stageIds} from "./store.js";

const ORDER = ["raw", ...STAGE_NAMES];

/** Name of the furthest stage that has an output for this id. */
function latestStage(batch: string, id: string): string {
  for (const stage of [...ORDER].reverse()) if (hasStage(batch, stage, id)) return stage;
  return "none";
}

/** Markdown summary of a batch: one row per recipe plus errors and pending ingredients. */
export function report(batch: string): string {
  const ids = [...new Set(ORDER.flatMap((stage) => stageIds(batch, stage)))].sort();
  const errors = readJson<Record<string, {stage: string; message: string}>>(join(batchDir(batch), "errors.json"), {});
  const lines: string[] = [`# Batch ${batch} — ${ids.length} recipes`, ""];
  lines.push("| id | stage | title (fr) | tier | kcal | prot | fat% | veg g | carbs | serv | € | craving | cuisine | suitable | review |");
  lines.push("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|");

  for (const id of ids) {
    const stage = latestStage(batch, id);
    const doc = stage === "raw" ? null : readStage<any>(batch, stage, id);
    const error = errors[id] ? ` ❌ ${errors[id].stage}: ${errors[id].message.slice(0, 80)}` : "";
    if (!doc) {
      const title = hasStage(batch, "raw", id) ? readStage<any>(batch, "raw", id).raw.title : "";
      lines.push(`| ${id} | ${stage} | ${title} | | | | | | | | | | | |${error} |`);
      continue;
    }
    if (doc.rejected) {
      lines.push(`| ${id} | clean | ${doc.title?.fr ?? ""} | rejected: ${doc.rejected} | | | | | | | | | | | |`);
      continue;
    }
    const m = doc.portion?.macros;
    const n = doc.servings;
    const fatShare = m && m.kcal ? Math.round((m.fat * 9 * 100) / m.kcal) : "";
    const veg = doc.dish && n ? Math.round(doc.dish.vegGrams / n) : "";
    const suitable = doc.suitable ? Object.entries(doc.suitable).filter(([, v]) => v).map(([k]) => k.replace("_free", "¬")).join(" ") : "";
    const notes = [...(doc.reviewNotes ?? [])];
    if (doc.duplicateOf) notes.unshift(`dup of ${doc.duplicateOf}`);
    const review = notes.length ? `⚠ ${notes.join("; ")}` : "";
    lines.push(`| ${id} | ${stage} | ${doc.title.fr} | ${doc.tier ?? ""} | ${m?.kcal ?? ""} | ${m?.protein ?? ""} | ${fatShare} | ${veg} | ${m?.carbs ?? ""} ` +
      `| ${doc.claimedServings}→${n ?? "?"} | ${doc.pricePerPortion ?? ""} | ${doc.tags?.craving ?? ""} | ${doc.tags?.cuisine ?? ""} | ${suitable} | ${review}${error} |`);
  }

  const pending = Object.values(masterTable()).filter((r) => r.status === "pending");
  if (pending.length) {
    lines.push("", `## Pending ingredients (${pending.length})`, "");
    lines.push("| slug | fr | aisle | ciqual | €/kg | g/unit | flags |", "|---|---|---|---|---|---|---|");
    for (const r of pending) {
      const flags = Object.entries(r.flags).filter(([, v]) => v).map(([k]) => k).join(" ");
      const gpu = Object.entries(r.gramsPerUnit).map(([u, g]) => `${u}=${g}`).join(" ");
      lines.push(`| ${r.slug} | ${r.name.fr} | ${r.aisle} | ${r.ciqualCode ?? "—"} | ${r.pricePerKg ?? "—"} | ${gpu} | ${flags} |`);
    }
  }
  return lines.join("\n");
}
