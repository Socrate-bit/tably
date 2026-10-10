import {createServer} from "node:http";
import {existsSync, readFileSync} from "node:fs";
import {extname, join, resolve} from "node:path";
import {getIngredient} from "./ingredients.js";
import {TIERS} from "./config.js";
import type {RecipeDoc, Unit} from "./schema.js";
import {roundAmount} from "./units.js";
import {batchDir, hasStage, readStage, stageIds, writeJson} from "./store.js";

/** Everything the review page shows for one recipe: source, cleaned, final, and pipeline commentary. */
function recipeView(batch: string, id: string): Record<string, unknown> {
  const raw = readStage<any>(batch, "raw", id).raw;
  const source = {
    title: raw.title,
    url: raw.sourceUrl,
    image: raw.image,
    servings: raw.servings,
    readyInMinutes: raw.readyInMinutes,
    nutrition: Object.fromEntries(["Calories", "Protein", "Carbohydrates", "Fat"].map((n) =>
      [n, raw.nutrition?.nutrients?.find((x: any) => x.name === n)?.amount ?? null])),
    pricePerServingEur: raw.pricePerServing ? Math.round(raw.pricePerServing * 0.86) / 100 : null,
    ingredients: (raw.extendedIngredients ?? []).map((i: any) => i.original),
    steps: (raw.analyzedInstructions ?? []).flatMap((a: any) => a.steps ?? []).map((s: any) => s.step),
    cuisines: raw.cuisines, dishTypes: raw.dishTypes, diets: raw.diets,
  };
  const clean = hasStage(batch, "clean", id) ? readStage<any>(batch, "clean", id) : null;
  const latestName = ["photo", "dedupe", "check", "price", "tag", "portion", "balance", "nutrition", "map", "clean"]
    .find((s) => hasStage(batch, s, id)) ?? "raw";
  const latest = latestName === "raw" ? null : readStage<any>(batch, latestName, id);
  const final = hasStage(batch, "final", id) ? readStage<RecipeDoc>(batch, "final", id) : null;
  const errors = readJsonSafe<Record<string, any>>(join(batchDir(batch), "errors.json"))?.[id] ?? null;

  const name = (slug: string) => getIngredient(slug)?.name.fr ?? slug;
  const comments: {level: "ok" | "warn" | "bad"; text: string}[] = [];
  if (clean?.rejected) comments.push({level: "bad", text: `Rejected at clean: ${clean.rejected}`});
  if (latest?.balance) {
    const b = latest.balance;
    comments.push({level: b.changed ? "warn" : "ok", text: b.changed ? `Balance rewrote the recipe: ${b.changes.join(" · ")}` : "Balance: no change needed"});
    if (b.indulgentStyle) comments.push({level: "ok", text: "Classified indulgent: fat cap not applied"});
  }
  if (latest?.servings && clean) {
    const ratio = latest.servings / clean.claimedServings;
    if (ratio >= 1.5 || ratio <= 0.67) comments.push({level: "warn", text: `Servings ${clean.claimedServings} → ${latest.servings}: the source portion size was far from the ${latest.tier} band`});
  }
  if (latest?.portion) {
    const prot = latest.portion.lines.filter((l: any) => {
      const f = getIngredient(l.ingredientId)?.flags;
      return f && (f.isMeat || f.isFish);
    }).reduce((s: number, l: any) => s + l.grams, 0);
    if (prot > 0 && prot < 110) comments.push({level: "bad", text: `Only ${Math.round(prot)} g of meat/fish per portion (target 120–150 g): balance stretched the dish instead of scaling the protein`});
    const m = latest.portion.macros;
    const fat = m.kcal ? Math.round((m.fat * 9 * 100) / m.kcal) : 0;
    const t = TIERS[latest.tier as "light" | "regular"];
    comments.push({level: m.kcal >= t.kcalMin && m.kcal <= t.kcalMax ? "ok" : "warn", text: `${m.kcal} kcal/portion, tier ${latest.tier} (band ${t.kcalMin}–${t.kcalMax}); protein ${m.protein} g (floor ${t.proteinMin}); fat ${fat}% (cap ${t.fatShareMax * 100}%)`});
  }
  if (latest?.steps?.some((s: any) => /\b\d+\s?(g|ml|cl|kg|l|tbsp|tsp)\b|\d\s?c\. à/i.test(s.fr))) {
    comments.push({level: "bad", text: "Steps contain whole-dish quantities while the ingredient list is per portion: they will disagree once the app scales by household"});
  }
  const estimated = (latest?.lines ?? []).map((l: any) => getIngredient(l.ingredientId)).filter((r: any) => r && r.priceSource === "llm_estimate");
  if (estimated.length) comments.push({level: "warn", text: `Price uses LLM estimates for: ${estimated.map((r: any) => r.name.fr).join(", ")}`});
  const noCiqual = (latest?.lines ?? []).map((l: any) => getIngredient(l.ingredientId)).filter((r: any) => r && !r.ciqualCode);
  if (noCiqual.length) comments.push({level: "warn", text: `No CIQUAL match (LLM nutrition estimate) for: ${noCiqual.map((r: any) => r.name.fr).join(", ")}`});
  if (latest?.suitableOverrides?.length) comments.push({level: "warn", text: `Diet flags switched off by the LLM: ${latest.suitableOverrides.map((o: any) => `${o.flag} (${o.reason})`).join("; ")}`});
  if (latest?.review) comments.push({level: latest.review.verdict === "approve" ? "ok" : "bad", text: `Reviewer (${latest.review.verdict}, ${latest.review.score}/10): ${latest.review.notes.join(" · ") || "no remarks"}`});
  if (latest?.photo) comments.push({level: latest.photo.verified ? "ok" : "bad", text: `Photo: ${latest.photo.attempts} attempt(s), ${latest.photo.verified ? "verified" : "NOT verified"}`});
  if (latest?.duplicateOf) comments.push({level: "bad", text: `Duplicate of ${latest.duplicateOf}`});
  for (const n of latest?.reviewNotes ?? []) comments.push({level: "warn", text: `Review note: ${n}`});
  if (errors) comments.push({level: "bad", text: `Failed at ${errors.stage}: ${errors.message}`});

  const stages = [
    clean && {name: "clean", summary: clean.rejected ? `rejected: ${clean.rejected}` : `${source.steps.length} → ${clean.steps.length} steps, ${source.ingredients.length} → ${clean.lines.length} ingredients`, notes: clean.cleanNotes},
    latest?.unmapped !== undefined && {name: "map", summary: `${latest.lines.length} lines linked, ${latest.newIngredients.length} new ingredient rows`, notes: latest.unmapped},
    latest?.dish && {name: "nutrition", summary: `dish ${latest.dish.grams} g, ${latest.dish.kcal} kcal, density ${latest.density} kcal/100 g → ${latest.tier}`, notes: []},
    latest?.balance && {name: "balance", summary: latest.balance.changed ? "rewritten" : "unchanged", notes: latest.balance.changes.length ? latest.balance.changes : [`floors: ${JSON.stringify(latest.balance.floors)}`]},
    latest?.servings && {name: "portion", summary: `${clean.claimedServings} → ${latest.servings} servings, ${latest.portion.macros.kcal} kcal/portion`, notes: []},
    latest?.tags && {name: "tag", summary: `${latest.tags.totalMinutes} min (${latest.tags.activeMinutes} active), ${latest.tags.difficulty}, cravings [${(latest.tags.cravings ?? [latest.tags.craving]).join(", ")}], ${latest.tags.protein}, cuisines [${(latest.tags.cuisines ?? [latest.tags.cuisine]).join(", ")}], [${latest.tags.appliances.join(", ")}]`, notes: latest.suitableOverrides?.map((o: any) => `${o.flag} → false: ${o.reason}`) ?? []},
    latest?.review && {name: "check", summary: `${latest.review.verdict} (${latest.review.score}/10)`, notes: latest.review.notes},
    latest?.pricePerPortion !== undefined && {name: "price", summary: `${latest.pricePerPortion} € / portion (coverage ${latest.priceCoverage})`, notes: latest.unpriced},
    latest?.dedupeCandidates && {name: "dedupe", summary: latest.duplicateOf ? `duplicate of ${latest.duplicateOf}` : `no duplicate (${latest.dedupeCandidates.length} candidates)`, notes: latest.dedupeCandidates.map((c: any) => `${c.id} ${c.reason} ${c.score.toFixed(2)} ${c.confirmed ? "confirmed" : "rejected"}`)},
    latest?.photo && {name: "photo", summary: `${latest.photo.attempts} attempt(s), ${latest.photo.verified ? "verified" : "not verified"}`, notes: []},
    final && {name: "final", summary: `status ${final.status}`, notes: final.reviewNotes},
  ].filter(Boolean);

  return {
    id, latestStage: latestName, source,
    clean: clean && {
      title: clean.title, claimedServings: clean.claimedServings, rejected: clean.rejected,
      ingredients: clean.lines.map((l: any) => ({text: `${l.amount} ${l.unit} ${l.name}`, note: l.note?.fr, optional: l.optional, original: l.original})),
      steps: clean.steps,
    },
    final: latest?.portion && {
      title: latest.title, status: final?.status ?? "—", tier: latest.tier, servings: latest.servings, macros: latest.portion.macros,
      price: latest.pricePerPortion, tags: latest.tags, suitable: latest.suitable, photo: latest.photo ? `photos/${id}/hero.jpg` : null,
      ingredients: latest.portion.lines.map((l: any) => ({text: `${fmt(l.amount, l.unit)} ${name(l.ingredientId)}${l.alternativeId ? ` (ou ${name(l.alternativeId)})` : ""}`, exact: `${l.amount} ${l.unit}`, grams: l.grams, note: l.note?.fr, optional: l.optional, slug: l.ingredientId})),
      steps: latest.steps.map((s: any) => ({fr: renderTokens(s.fr, latest, "fr"), en: renderTokens(s.en, latest, "en"), rawFr: s.fr})),
      balance: latest.balance, review: latest.review ?? null,
    },
    stages, comments,
  };
}

/** What the app will show for a token at the stored servings count: "200 g de pavé de saumon". */
function renderTokens(text: string, doc: any, lang: "fr" | "en"): string {
  return text.replace(/\{([^{}]+)\}/g, (whole, slug: string) => {
    const line = doc.portion.lines.find((l: any) => l.ingredientId === slug);
    if (!line) return whole;
    const name = getIngredient(slug)?.name[lang] ?? slug;
    const shown = fmt(line.amount * doc.servings, line.unit);
    return line.unit === "to_taste" ? name : `<b>${shown} ${lang === "fr" && !/piece/.test(line.unit) ? "de " : ""}${name}</b>`.replace(/\s+/g, " ");
  });
}

/** Display rounding, the rule the app applies AFTER scaling: ½ pieces, 1/5/10 g steps, ¼ spoons. */
function fmt(amount: number, unit: string): string {
  if (unit === "to_taste") return "";
  if (unit === "pinch") return "1 pincée";
  const r = roundAmount(amount, unit as Unit);
  const label = unit === "piece" ? "" : unit;
  return `${Number.isInteger(r) ? r : r.toString().replace(".5", "½").replace("0.25", "¼").replace("0.75", "¾")} ${label}`.trim();
}

function readJsonSafe<T>(path: string): T | null {
  return existsSync(path) ? (JSON.parse(readFileSync(path, "utf8")) as T) : null;
}

/** Write review/data.json for the batch and serve the batch folder on localhost. */
export function serveReview(batch: string, port: number): void {
  const ids = stageIds(batch, "raw");
  const data = ids.map((id) => recipeView(batch, id));
  const dir = batchDir(batch);
  writeJson(join(dir, "review", "data.json"), data);
  const html = readFileSync(join(resolve(import.meta.dirname, ".."), "review.html"), "utf8");
  const types: Record<string, string> = {".json": "application/json", ".jpg": "image/jpeg", ".png": "image/png", ".html": "text/html"};
  createServer((req, res) => {
    const path = decodeURIComponent((req.url ?? "/").split("?")[0]);
    if (path === "/" || path === "/index.html") {
      res.writeHead(200, {"content-type": "text/html; charset=utf-8"});
      res.end(html);
      return;
    }
    const file = join(dir, path);
    if (!file.startsWith(dir) || !existsSync(file)) {
      res.writeHead(404);
      res.end("not found");
      return;
    }
    res.writeHead(200, {"content-type": types[extname(file)] ?? "application/octet-stream"});
    res.end(readFileSync(file));
  }).listen(port, () => console.log(`[review] ${ids.length} recipes at http://localhost:${port}`));
}
