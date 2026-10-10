import {z} from "zod";
type Floors = z.infer<typeof Floors2>;
import {CARBS_MIN_REGULAR, FLOOR_SLACK, FLOOR_SLACK_AFTER, MAIN_PROTEIN_GRAMS_MIN, MODELS, TIERS} from "../config.js";
import {getIngredient} from "../ingredients.js";
import {jsonCall} from "../llm.js";
import type {Stage} from "../runner.js";
import {type BalancedDoc, CleanLine, type Floors2, Lang, type NutritionDoc} from "../schema.js";
import {loadPrompt} from "../store.js";
import {round} from "../units.js";
import {mapLines} from "./map.js";
import {computeNutrition} from "./nutrition.js";

const BalanceOut = z.object({
  /** Deliberately rich dish (indulgent / fakeaway): the fat cap does not apply. */
  indulgentStyle: z.boolean(),
  changed: z.boolean(),
  changes: z.array(z.string()),
  lines: z.array(CleanLine).nullable(),
  steps: z.array(Lang).nullable(),
});

/** Servings the dish would be cut into at the tier's target kcal; floors are judged per such portion. */
export function provisionalServings(doc: NutritionDoc): number {
  return Math.max(1, Math.round(doc.dish.kcal / TIERS[doc.tier].kcalTarget));
}

/** Which floors the dish meets, per provisional portion. */
export function checkFloors(doc: NutritionDoc, indulgentStyle: boolean, slack = FLOOR_SLACK): Floors {
  const tier = TIERS[doc.tier];
  const n = provisionalServings(doc);
  const fatShare = doc.dish.kcal > 0 ? (doc.dish.fat * 9) / doc.dish.kcal : 0;
  const meatFish = doc.lines.reduce((sum, l) => {
    const f = getIngredient(l.ingredientId)?.flags;
    return f && (f.isMeat || f.isFish) ? sum + l.grams : sum;
  }, 0);
  return {
    protein: doc.dish.protein / n >= tier.proteinMin - slack.protein,
    // Fat is soft: it is reported, and only an extreme excess is treated as a failure.
    fat: indulgentStyle || fatShare <= tier.fatShareMax + 0.15,
    veg: doc.dish.vegGrams / n >= tier.vegMin - slack.veg,
    carb: doc.tier === "light" || doc.dish.carbs / n >= CARBS_MIN_REGULAR - slack.carbs,
    mainProtein: meatFish === 0 || meatFish / n >= MAIN_PROTEIN_GRAMS_MIN - 10,
  };
}

const allPass = (f: Floors): boolean => Object.values(f).every(Boolean);

/** Per-portion numbers the prompt reasons about. */
function portionView(doc: NutritionDoc): Record<string, number> {
  const n = provisionalServings(doc);
  return {
    servings: n,
    kcal: round(doc.dish.kcal / n, 0),
    protein: round(doc.dish.protein / n),
    carbs: round(doc.dish.carbs / n),
    fat: round(doc.dish.fat / n),
    fatShareOfKcal: round(doc.dish.kcal > 0 ? (doc.dish.fat * 9) / doc.dish.kcal : 0, 2),
    vegGrams: round(doc.dish.vegGrams / n, 0),
    meatFishGrams: round(doc.lines.reduce((s, l) => {
      const f = getIngredient(l.ingredientId)?.flags;
      return f && (f.isMeat || f.isFish) ? s + l.grams : s;
    }, 0) / n, 0),
  };
}

/**
 * LLM: when a floor fails, rewrite the ingredient list and steps minimally so the
 * dish meets its tier, then re-map and re-compute once. Skipped when all pass.
 */
export const balanceStage: Stage<NutritionDoc, BalancedDoc> = {
  name: "balance",
  prev: "nutrition",
  async run(input, ctx) {
    const reviewNotes: string[] = [...input.unmapped];
    let doc = input;
    let floors = checkFloors(doc, false);
    if (allPass(floors)) {
      return {...doc, balance: {changed: false, indulgentStyle: false, changes: [], floors}, needsReview: reviewNotes.length > 0, reviewNotes};
    }

    const tier = TIERS[doc.tier];
    const out = await jsonCall({
      model: MODELS.strong,
      system: loadPrompt("balance"),
      input: {
        title: doc.title.en,
        tier: doc.tier,
        rules: {
          proteinMinPerPortion: tier.proteinMin,
          fatShareMax: tier.fatShareMax,
          vegGramsMinPerPortion: tier.vegMin,
          carbsMinPerPortion: doc.tier === "regular" ? CARBS_MIN_REGULAR : 0,
          meatFishGramsMinPerPortion: MAIN_PROTEIN_GRAMS_MIN,
        },
        perPortion: portionView(doc),
        floorsMet: floors,
        lines: doc.lines.map((l) => ({
          name: l.name, amount: l.amount, unit: l.unit, grams: l.grams, note: l.note, optional: l.optional, original: l.original,
          flags: getIngredient(l.ingredientId)?.flags ?? null,
        })),
        steps: doc.steps,
      },
      schema: BalanceOut,
      label: `balance ${ctx.id}`,
    });

    if (out.changed && out.lines && out.steps) {
      const remapped = await mapLines({...doc, lines: out.lines, steps: out.steps}, ctx.id);
      doc = computeNutrition(remapped);
      reviewNotes.push(...doc.unmapped.filter((n) => !reviewNotes.includes(n)));
    }
    floors = checkFloors(doc, out.indulgentStyle, FLOOR_SLACK_AFTER);
    if (!allPass({...floors, mainProtein: true})) {
      const failed = Object.entries(floors).filter(([k, ok]) => !ok && k !== "mainProtein").map(([k]) => k);
      reviewNotes.push(`floors not met after balance: ${failed.join(", ")} (${JSON.stringify(portionView(doc))})`);
    }
    return {
      ...doc,
      balance: {changed: out.changed, indulgentStyle: out.indulgentStyle, changes: out.changes, floors},
      needsReview: reviewNotes.length > 0,
      reviewNotes,
    };
  },
};
