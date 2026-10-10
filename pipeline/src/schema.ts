import {z} from "zod";
import {AISLES, ALLERGENS, APPLIANCES, CRAVINGS, CUISINES, DIFFICULTIES, PROTEINS, SUITABLE_KEYS,
  TIER_IDS, UNITS} from "./config.js";

// ---------------------------------------------------------------------------
// Shared value types
// ---------------------------------------------------------------------------

export const Lang = z.object({fr: z.string(), en: z.string()});
export type Lang = z.infer<typeof Lang>;

export const Unit = z.enum(UNITS);
export type Unit = z.infer<typeof Unit>;
export const Aisle = z.enum(AISLES);
export const Allergen = z.enum(ALLERGENS);
export type Allergen = z.infer<typeof Allergen>;
export const Craving = z.enum(CRAVINGS);
export const Protein = z.enum(PROTEINS);
export const Appliance = z.enum(APPLIANCES);
export const Difficulty = z.enum(DIFFICULTIES);
export const Cuisine = z.enum(CUISINES);
export const Tier = z.enum(TIER_IDS);
export type Tier = z.infer<typeof Tier>;

export const Macros = z.object({
  kcal: z.number(), protein: z.number(), carbs: z.number(), fat: z.number(),
  fiber: z.number(), salt: z.number(), sugars: z.number(),
});
export type Macros = z.infer<typeof Macros>;
export const MACRO_KEYS = ["kcal", "protein", "carbs", "fat", "fiber", "salt", "sugars"] as const;

export const Suitable = z.object(Object.fromEntries(SUITABLE_KEYS.map((k) => [k, z.boolean()])) as
  Record<(typeof SUITABLE_KEYS)[number], z.ZodBoolean>);
export type Suitable = z.infer<typeof Suitable>;

// ---------------------------------------------------------------------------
// Master ingredient table (data/ingredients.json)
// ---------------------------------------------------------------------------

export const IngredientFlags = z.object({
  isPork: z.boolean(), isMeat: z.boolean(), isFish: z.boolean(), isAnimal: z.boolean(),
  hasAlcohol: z.boolean(), isVegetable: z.boolean(), isCarb: z.boolean(),
});
export type IngredientFlags = z.infer<typeof IngredientFlags>;

export const MasterIngredient = z.object({
  slug: z.string(),
  name: Lang,
  aliases: z.array(z.string()),
  icon: z.string(),
  aisle: Aisle,
  allergens: z.array(Allergen),
  flags: IngredientFlags,
  /** Grams of one unit (piece, clove, tbsp…). Weight and volume units never appear here. */
  gramsPerUnit: z.record(z.string(), z.number()),
  densityGPerMl: z.number().nullable(),
  ciqualCode: z.string().nullable(),
  /** LLM estimate per 100 g, used only when no CIQUAL code fits. */
  per100g: Macros.nullable(),
  pricePerKg: z.number().nullable(),
  priceSource: z.enum(["csv", "web", "llm_estimate"]).nullable(),
  /** Where per100g came from when not CIQUAL. */
  nutritionSource: z.enum(["ciqual", "usda", "llm_estimate"]).nullable(),
  status: z.enum(["approved", "pending"]),
});
export type MasterIngredient = z.infer<typeof MasterIngredient>;

/** Per-100 g values kept from CIQUAL, keyed by alim_code. */
export const CiqualFood = z.object({name: Lang, per100g: Macros});
export type CiqualFood = z.infer<typeof CiqualFood>;

// ---------------------------------------------------------------------------
// Stage documents. Each stage extends the previous one.
// ---------------------------------------------------------------------------

export const CleanLine = z.object({
  /** Generic English ingredient name, singular, no preparation words. */
  name: z.string(),
  /** Whole-dish amount for `claimedServings`. */
  amount: z.number(),
  unit: Unit,
  note: Lang.nullable(),
  optional: z.boolean(),
  /** A more common substitute for a hard-to-find ingredient ("X or Y"), generic English name or null. */
  alternative: z.string().nullable(),
  /** Source line, kept for debugging. */
  original: z.string(),
});
export type CleanLine = z.infer<typeof CleanLine>;

export const CleanDoc = z.object({
  id: z.string(),
  /** Set on a derived twin (light/regular version of another recipe). */
  variantOf: z.string().nullable().default(null),
  sourceId: z.number(),
  sourceUrl: z.string().nullable(),
  sourceName: z.string().nullable(),
  imageUrl: z.string().nullable(),
  title: Lang,
  steps: z.array(Lang),
  claimedServings: z.number(),
  lines: z.array(CleanLine),
  cleanNotes: z.array(z.string()),
  /** Set when the recipe is not a usable main course; later stages skip it. */
  rejected: z.string().nullable(),
});
export type CleanDoc = z.infer<typeof CleanDoc>;

export const MappedLine = CleanLine.extend({
  ingredientId: z.string(),
  alternativeId: z.string().nullable(),
  grams: z.number(),
  gramsBasis: z.enum(["weight", "volume", "count", "none"]),
});
export type MappedLine = z.infer<typeof MappedLine>;

export const MappedDoc = CleanDoc.extend({
  lines: z.array(MappedLine),
  unmapped: z.array(z.string()),
  newIngredients: z.array(z.string()),
});
export type MappedDoc = z.infer<typeof MappedDoc>;

export const DishTotals = Macros.extend({grams: z.number(), vegGrams: z.number(), carbGrams: z.number()});
export type DishTotals = z.infer<typeof DishTotals>;

export const NutritionDoc = MappedDoc.extend({
  dish: DishTotals,
  /** kcal per 100 g of finished dish. */
  density: z.number(),
  tier: Tier,
});
export type NutritionDoc = z.infer<typeof NutritionDoc>;

export const Floors = z.object({protein: z.boolean(), fat: z.boolean(), veg: z.boolean(), carb: z.boolean()});
export type Floors = z.infer<typeof Floors>;

export const Floors2 = Floors.extend({mainProtein: z.boolean()});
export const BalancedDoc = NutritionDoc.extend({
  balance: z.object({changed: z.boolean(), indulgentStyle: z.boolean(), changes: z.array(z.string()), floors: Floors2}),
  needsReview: z.boolean(),
  reviewNotes: z.array(z.string()),
});
export type BalancedDoc = z.infer<typeof BalancedDoc>;

export const PortionedDoc = BalancedDoc.extend({
  servings: z.number(),
  portion: z.object({lines: z.array(MappedLine), macros: Macros}),
});
export type PortionedDoc = z.infer<typeof PortionedDoc>;

export const Tags = z.object({
  activeMinutes: z.number(),
  totalMinutes: z.number(),
  difficulty: Difficulty,
  /** Primary craving (card badge); `cravings` holds every one that fits. */
  craving: Craving,
  cravings: z.array(Craving),
  protein: Protein,
  cuisine: Cuisine,
  cuisines: z.array(Cuisine),
  appliances: z.array(Appliance),
  keywords: z.array(z.string()),
});
export type Tags = z.infer<typeof Tags>;

export const SuitableOverride = z.object({flag: z.enum(SUITABLE_KEYS), reason: z.string()});

export const TaggedDoc = PortionedDoc.extend({
  tags: Tags,
  suitable: Suitable,
  suitableOverrides: z.array(SuitableOverride),
});
export type TaggedDoc = z.infer<typeof TaggedDoc>;

export const PricedDoc = TaggedDoc.extend({
  pricePerPortion: z.number(),
  /** Share of the dish weight that had a price. */
  priceCoverage: z.number(),
  unpriced: z.array(z.string()),
});
export type PricedDoc = z.infer<typeof PricedDoc>;

/** Verdict of the LLM reviewer (replaces the human gate). */
export const Review = z.object({
  verdict: z.enum(["approve", "reject"]),
  /** 1–10 overall quality the reviewer gives the recipe as a French home dinner. */
  score: z.number(),
  notes: z.array(z.string()),
});
export const CheckedDoc = PricedDoc.extend({review: Review});
export type CheckedDoc = z.infer<typeof CheckedDoc>;

export const DedupeCandidate = z.object({
  id: z.string(), reason: z.enum(["sourceId", "title", "jaccard"]), score: z.number(), confirmed: z.boolean(),
});
export const DedupedDoc = PricedDoc.extend({
  duplicateOf: z.string().nullable(),
  dedupeCandidates: z.array(DedupeCandidate),
});
export type DedupedDoc = z.infer<typeof DedupedDoc>;

export const PhotoDoc = PricedDoc.extend({
  photo: z.object({
    heroPath: z.string(), thumbPath: z.string(), blurhash: z.string(), attempts: z.number(), verified: z.boolean(),
  }),
});
export type PhotoDoc = z.infer<typeof PhotoDoc>;

// ---------------------------------------------------------------------------
// Final Firestore documents
// ---------------------------------------------------------------------------

export const RecipeIngredient = z.object({
  ingredientId: z.string(),
  alternativeId: z.string().nullable(),
  amount: z.number(),
  unit: Unit,
  grams: z.number(),
  note: Lang.nullable(),
  optional: z.boolean(),
});

export const RecipeDoc = z.object({
  id: z.string(),
  status: z.enum(["published", "draft"]),
  /** The other version of this dish (light ↔ regular), when it exists. */
  variantOf: z.string().nullable(),
  variantId: z.string().nullable(),
  sourceId: z.number(),
  sourceUrl: z.string().nullable(),
  sourceName: z.string().nullable(),
  title: Lang,
  steps: z.array(Lang).min(3),
  servings: z.number().int().min(1),
  totalMinutes: z.number().int().positive(),
  activeMinutes: z.number().int().positive(),
  difficulty: Difficulty,
  tier: Tier,
  /** Per portion. */
  ingredients: z.array(RecipeIngredient).min(1),
  /** Per portion. */
  macros: Macros,
  craving: Craving,
  cravings: z.array(Craving),
  protein: Protein,
  cuisine: Cuisine,
  cuisines: z.array(Cuisine),
  appliances: z.array(Appliance),
  suitable: Suitable,
  pricePerPortion: z.number().nonnegative(),
  reviewScore: z.number(),
  photo: z.object({hero: z.string(), thumb: z.string(), blurhash: z.string()}),
  rand: z.number(),
  keywords: z.array(z.string()),
  createdAt: z.string(),
  updatedAt: z.string(),
  pipelineVersion: z.string(),
  needsReview: z.boolean(),
  reviewNotes: z.array(z.string()),
});
export type RecipeDoc = z.infer<typeof RecipeDoc>;

/** Public subset of a master row, written to ingredients/{slug}. */
export const IngredientDoc = MasterIngredient.omit({status: true, aliases: true});
export type IngredientDoc = z.infer<typeof IngredientDoc>;

/** One row of work/published-index.json and the in-batch dedupe index. */
export const IndexEntry = z.object({
  id: z.string(), sourceId: z.number(), titleEn: z.string(), ingredientIds: z.array(z.string()), protein: Protein,
});
export type IndexEntry = z.infer<typeof IndexEntry>;
