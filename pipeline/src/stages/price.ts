import {getIngredient} from "../ingredients.js";
import type {Stage} from "../runner.js";
import type {PricedDoc, TaggedDoc} from "../schema.js";
import {round} from "../units.js";

/** Price per portion = Σ grams × €/kg over the per-portion lines; unpriced rows are reported, never silently 0. */
export const priceStage: Stage<TaggedDoc, PricedDoc> = {
  name: "price",
  prev: "tag",
  async run(input) {
    let price = 0;
    let pricedGrams = 0;
    let totalGrams = 0;
    const unpriced: string[] = [];
    for (const line of input.portion.lines) {
      if (line.grams <= 0) continue;
      const row = getIngredient(line.ingredientId);
      totalGrams += line.grams;
      if (row?.pricePerKg != null) {
        price += (line.grams * row.pricePerKg) / 1000;
        pricedGrams += line.grams;
      } else {
        unpriced.push(line.ingredientId);
      }
    }
    const priceCoverage = totalGrams > 0 ? round(pricedGrams / totalGrams, 2) : 0;
    const reviewNotes = [...input.reviewNotes];
    if (priceCoverage < 0.9) reviewNotes.push(`price coverage ${priceCoverage}; unpriced: ${unpriced.join(", ")}`);
    return {...input, pricePerPortion: round(price, 2), priceCoverage, unpriced, reviewNotes, needsReview: reviewNotes.length > 0};
  },
};
