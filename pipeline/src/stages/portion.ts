import {MAIN_PROTEIN_GRAMS_MIN, MAX_SERVINGS, TIERS} from "../config.js";
import {getIngredient} from "../ingredients.js";
import type {Stage} from "../runner.js";
import {type BalancedDoc, MACRO_KEYS, type Macros, type MappedLine, type PortionedDoc} from "../schema.js";
import {isCount, round} from "../units.js";
import {sumLines} from "./nutrition.js";


/** Lower is better: distance to the tier target, out-of-band penalty, awkward counts (weighted by weight), drift from the source. */
function score(doc: BalancedDoc, n: number): number {
  const tier = TIERS[doc.tier];
  const kcal = doc.dish.kcal / n;
  let awkwardShare = 0;
  for (const l of doc.lines) {
    if (isCount(l.unit) && Math.abs(((l.amount / n) * 2) % 1) > 1e-6) awkwardShare += l.grams / Math.max(1, doc.dish.grams);
  }
  return Math.abs(kcal - tier.kcalTarget)
    + (kcal < tier.kcalMin || kcal > tier.kcalMax ? 60 : 0)
    + 25 * awkwardShare
    + (10 * Math.abs(n - doc.claimedServings)) / doc.claimedServings;
}

/**
 * One line divided by the servings, kept EXACT (3 decimals) in its natural unit:
 * the app multiplies by the household and rounds at display time, which is the
 * only place rounding is correct. pinch / to_taste stay 1.
 */
function portionLine(line: MappedLine, servings: number): MappedLine {
  if (line.unit === "to_taste" || line.unit === "pinch") return {...line, amount: 1, grams: round(line.grams / servings, 2)};
  return {...line, amount: round(line.amount / servings, 3), grams: round(line.grams / servings, 1)};
}

/** Choose the servings count and divide the dish into per-portion amounts. */
export function portionDoc(doc: BalancedDoc): PortionedDoc {
  let servings = 1;
  let best = Infinity;
  for (let n = 1; n <= MAX_SERVINGS; n++) {
    const s = score(doc, n);
    if (s < best - 1e-9) {
      best = s;
      servings = n;
    }
  }
  let lines = doc.lines.map((l) => portionLine(l, servings));
  // Hard floor the LLM cannot skip: a meat/fish main keeps ≥ 120 g raw meat/fish per portion.
  const isMain = (l: MappedLine) => {
    const f = getIngredient(l.ingredientId)?.flags;
    return !!f && (f.isMeat || f.isFish);
  };
  const meatFish = lines.filter(isMain).reduce((s, l) => s + l.grams, 0);
  const changes = [...doc.balance.changes];
  if (meatFish > 0 && meatFish < MAIN_PROTEIN_GRAMS_MIN) {
    const factor = MAIN_PROTEIN_GRAMS_MIN / meatFish;
    lines = lines.map((l) => isMain(l) ? {...l, amount: round(l.amount * factor, 3), grams: round(l.grams * factor, 1)} : l);
    changes.push(`meat/fish scaled ×${factor.toFixed(2)} to reach ${MAIN_PROTEIN_GRAMS_MIN} g per portion (was ${Math.round(meatFish)} g)`);
  }
  // Per-portion macros come from the rounded lines, so the stored numbers match the stored amounts.
  const {totals} = sumLines(lines);
  const macros = Object.fromEntries(MACRO_KEYS.map((k) => [k, round(totals[k], k === "kcal" ? 0 : 1)])) as Macros;

  const tier = TIERS[doc.tier];
  const reviewNotes = [...doc.reviewNotes];
  if (macros.kcal < tier.kcalMin || macros.kcal > tier.kcalMax) {
    reviewNotes.push(`kcal per portion ${macros.kcal} outside ${doc.tier} band ${tier.kcalMin}-${tier.kcalMax}`);
  }
  const floors = {...doc.balance.floors, mainProtein: true};
  return {...doc, servings, portion: {lines, macros}, balance: {...doc.balance, changes, floors}, reviewNotes, needsReview: reviewNotes.length > 0};
}

export const portionStage: Stage<BalancedDoc, PortionedDoc> = {
  name: "portion",
  prev: "balance",
  run: async (input) => portionDoc(input),
};
