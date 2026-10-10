import {z} from "zod";
import {env, MODELS} from "./config.js";
import {jsonCall, textCall} from "./llm.js";
import {Macros, type MasterIngredient} from "./schema.js";

// ---------------------------------------------------------------------------
// USDA FoodData Central: nutrition fallback when CIQUAL has no match.
// ---------------------------------------------------------------------------

/** FDC nutrient numbers → our keys. Sodium is converted to salt (×2.5, mg → g). */
const FDC = {kcal: "208", protein: "203", carbs: "205", fat: "204", fiber: "291", sugars: "269", sodium: "307"} as const;

interface FdcFood {
  fdcId: number;
  description: string;
  dataType: string;
  foodNutrients: {nutrientNumber: string; value: number}[];
}

const UsdaPick = z.object({fdcId: z.number().nullable()});

/** Search FDC (Foundation + SR Legacy), let the lite model pick, fill per100g. */
export async function usdaNutrition(row: MasterIngredient): Promise<boolean> {
  const params = new URLSearchParams({
    query: row.name.en, dataType: "Foundation,SR Legacy", pageSize: "8", api_key: env.usdaKey,
  });
  const response = await fetch(`https://api.nal.usda.gov/fdc/v1/foods/search?${params}`, {signal: AbortSignal.timeout(20_000)});
  if (!response.ok) {
    console.warn(`[usda] ${row.slug}: ${response.status}`);
    return false;
  }
  const foods = ((await response.json()) as {foods?: FdcFood[]}).foods ?? [];
  if (!foods.length) return false;
  const pick = await jsonCall({
    model: MODELS.lite,
    system: "Pick the USDA food entry whose nutrition best represents the grocery ingredient as bought (raw, plain, generic), or null if none is close.",
    input: {ingredient: row.name, candidates: foods.map((f) => ({fdcId: f.fdcId, description: f.description, dataType: f.dataType}))},
    schema: UsdaPick,
    label: `usda ${row.slug}`,
  });
  const food = foods.find((f) => f.fdcId === pick.fdcId);
  if (!food) return false;
  const value = (n: string) => food.foodNutrients.find((x) => x.nutrientNumber === n)?.value ?? 0;
  row.per100g = Macros.parse({
    kcal: Math.round(value(FDC.kcal)), protein: value(FDC.protein), carbs: value(FDC.carbs), fat: value(FDC.fat),
    fiber: value(FDC.fiber), sugars: value(FDC.sugars), salt: Math.round(value(FDC.sodium) * 2.5) / 1000,
  });
  row.nutritionSource = "usda";
  return true;
}

// ---------------------------------------------------------------------------
// Web price: Gemini with Google Search grounding, for rows the CSV doesn't know.
// ---------------------------------------------------------------------------

const PriceOut = z.object({pricePerKg: z.number().nullable(), basis: z.string()});

/** Look up a current French supermarket €/kg and store it with priceSource "web". */
export async function webPrice(row: MasterIngredient): Promise<boolean> {
  const research = await textCall({
    model: MODELS.strong,
    prompt: `Quel est le prix actuel en supermarché en France (Leclerc, Carrefour, Intermarché, Lidl) de "${row.name.fr}" (${row.name.en}) ? ` +
      `Cherche des prix réels, cite le format vendu (par ex. "barquette 250 g à 2,49 €") et conclus par un prix moyen au kilo (ou au litre).`,
    search: true,
    label: `price-web ${row.slug}`,
  });
  const out = await jsonCall({
    model: MODELS.lite,
    system: "Extract the average supermarket price in EUR per kilogram (per litre for liquids) from the research text. If several prices, use a typical mid-range one. null when the text has no usable price.",
    input: research,
    schema: PriceOut,
    label: `price-parse ${row.slug}`,
  });
  if (!out.pricePerKg || out.pricePerKg <= 0) return false;
  row.pricePerKg = Math.round(out.pricePerKg * 100) / 100;
  row.priceSource = "web";
  return true;
}
