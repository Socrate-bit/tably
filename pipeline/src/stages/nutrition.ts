import {LIGHT_PORTION_GRAMS_MIN, TIERS} from "../config.js";
import {getIngredient, per100g} from "../ingredients.js";
import type {Stage} from "../runner.js";
import {type DishTotals, MACRO_KEYS, type MappedDoc, type MappedLine, type NutritionDoc} from "../schema.js";
import {round} from "../units.js";

/** Totals of a list of lines from grams × CIQUAL per 100 g. Also used per portion. */
export function sumLines(lines: MappedLine[]): {totals: DishTotals; missing: string[]} {
  const totals: DishTotals = {grams: 0, kcal: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, salt: 0, sugars: 0, vegGrams: 0, carbGrams: 0};
  const missing: string[] = [];
  for (const line of lines) {
    const row = getIngredient(line.ingredientId);
    if (!row || line.grams <= 0) continue;
    totals.grams += line.grams;
    if (row.flags.isVegetable) totals.vegGrams += line.grams;
    if (row.flags.isCarb) totals.carbGrams += line.grams;
    const values = per100g(row);
    if (!values) {
      missing.push(row.slug);
      continue;
    }
    for (const key of MACRO_KEYS) totals[key] += (line.grams * values[key]) / 100;
  }
  for (const key of Object.keys(totals) as (keyof DishTotals)[]) totals[key] = round(totals[key], 1);
  return {totals, missing};
}

/** Whole-dish totals; energy density decides the tier. */
export function computeNutrition(doc: MappedDoc): NutritionDoc {
  const {totals: dish, missing} = sumLines(doc.lines);
  const density = dish.grams > 0 ? round((dish.kcal / dish.grams) * 100, 1) : 0;
  const unmapped = [...doc.unmapped, ...missing.map((slug) => `${slug}: no nutrition data, counted as 0 kcal`)];
  // Regular by default; light only when a 650 kcal plate would be too big to eat.
  const regularPortionGrams = dish.kcal > 0 ? dish.grams / (dish.kcal / TIERS.regular.kcalTarget) : 0;
  return {...doc, unmapped, dish, density, tier: regularPortionGrams > LIGHT_PORTION_GRAMS_MIN ? "light" : "regular"};
}

export const nutritionStage: Stage<MappedDoc, NutritionDoc> = {
  name: "nutrition",
  prev: "map",
  run: async (input) => computeNutrition(input),
};
