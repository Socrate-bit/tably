import {existsSync} from "node:fs";
import {dirname, join} from "node:path";
import {fileURLToPath} from "node:url";

/** Absolute path of the pipeline/ folder, independent of the cwd. */
export const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
export const PATHS = {
  work: join(ROOT, "work"),
  data: join(ROOT, "data"),
  prompts: join(ROOT, "prompts"),
  assets: join(ROOT, "assets"),
  ingredients: join(ROOT, "data", "ingredients.json"),
  llmRequests: join(ROOT, "work", "llm", "requests"),
  llmResponses: join(ROOT, "work", "llm", "responses"),
  ciqual: join(ROOT, "data", "ciqual.json"),
  prices: join(ROOT, "data", "ingredient_prices.csv"),
  seen: join(ROOT, "work", "seen.json"),
  publishedIndex: join(ROOT, "work", "published-index.json"),
};

const envFile = join(ROOT, ".env");
if (existsSync(envFile)) process.loadEnvFile(envFile);

export const env = {
  spoonacularKey: process.env.SPOONACULAR_API_KEY ?? "",
  geminiKey: process.env.GEMINI_API_KEY ?? "",
  imageModel: process.env.IMAGE_MODEL || "gemini-3.1-flash-lite-image",
  photoMode: (process.env.PHOTO_MODE || "batch") as "batch" | "live",
  photoBatchWaitMinutes: Number(process.env.PHOTO_BATCH_WAIT_MINUTES || 120),
  reviewModel: process.env.REVIEW_MODEL || "gemini-3.8-flash",
  /** "gemini" calls the API; "files" writes requests for Claude Code subagents to answer. */
  llmBackend: (process.env.LLM_BACKEND || "gemini") as "gemini" | "files",
  usdaKey: process.env.USDA_API_KEY || "DEMO_KEY",
  firebaseProject: process.env.FIREBASE_PROJECT || "tably-9f3c2",
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "tably-9f3c2.firebasestorage.app",
};

/** Bumped whenever a prompt or rule changes the output shape or meaning. */
export const PIPELINE_VERSION = "2026.10.1";

// In files mode the ids name Claude tiers answered by Claude Code subagents.
const files = env.llmBackend === "files";
export const MODELS = {
  /** Judgment stages (clean, balance, ingredient proposals). */
  strong: files ? "claude:sonnet" : process.env.STRONG_MODEL || "gemini-3.8-flash",
  /** Mechanical calls (tag, picks, dedupe confirm, photo check). */
  lite: files ? "claude:haiku" : "gemini-3.1-flash-lite",
  /** Final reviewer and ingredient verification: the strongest model. */
  review: files ? "claude:opus" : env.reviewModel,
  image: env.imageModel,
};
export const LLM_CONCURRENCY = 4;

/**
 * A dish is `light` only when a regular (650 kcal) portion would weigh more than
 * this: it cannot reasonably be eaten as a regular main, so it is served as a
 * light one instead. Everything else is regular.
 */
export const LIGHT_PORTION_GRAMS_MIN = 600;
/** Raw meat or fish per portion a meat/fish main must keep. */
export const MAIN_PROTEIN_GRAMS_MIN = 120;

/** kcal per portion bands and the floors every recipe must meet, per tier. */
export const TIERS = {
  light: {kcalMin: 350, kcalMax: 500, kcalTarget: 425, proteinMin: 20, fatShareMax: 0.35, vegMin: 200},
  regular: {kcalMin: 550, kcalMax: 800, kcalTarget: 650, proteinMin: 25, fatShareMax: 0.40, vegMin: 150},
} as const;
/** Regular recipes under this many carbs per portion get a starch side. */
export const CARBS_MIN_REGULAR = 30;
/** Tolerance before a floor counts as failed (CIQUAL rounding should not trigger a rewrite). */
export const FLOOR_SLACK: FloorSlack = {protein: 1, fatShare: 0.02, veg: 10, carbs: 2};
/** Wider tolerance after the balance rewrite: a near miss is noted but does not block publishing. */
export const FLOOR_SLACK_AFTER: FloorSlack = {protein: 3, fatShare: 0.06, veg: 25, carbs: 6};
export interface FloorSlack {protein: number; fatShare: number; veg: number; carbs: number}
export const MAX_SERVINGS = 12;

// Enum ids. Cravings, appliances, aisles, allergies and proteins mirror the app
// (lib/core/model/preference_option.dart, aisle.dart, recipe.dart).
export const UNITS = ["g", "kg", "ml", "cl", "l", "tsp", "tbsp", "piece", "clove", "slice", "bunch",
  "sprig", "leaf", "stalk", "head", "can", "jar", "pack", "cube", "handful", "pinch", "to_taste"] as const;
export const WEIGHT_UNITS = ["g", "kg"] as const;
export const VOLUME_UNITS = ["ml", "cl", "l", "tsp", "tbsp"] as const;
export const COUNT_UNITS = ["piece", "clove", "slice", "bunch", "sprig", "leaf", "stalk", "head", "can",
  "jar", "pack", "cube", "handful"] as const;
export const AISLES = ["produce", "meat_fish", "pasta_rice", "tins_sauces", "herbs_grocery"] as const;
export const ALLERGENS = ["gluten", "milk", "nuts", "peanuts", "egg", "shellfish", "molluscs", "fish",
  "sesame", "soy", "celery", "mustard", "sulphites", "lupin"] as const;
export const CRAVINGS = ["quick", "high_protein", "low_calorie", "family_favourites", "healthy_comfort",
  "fakeaway", "easy_digestion", "indulgent"] as const;
export const PROTEINS = ["beef", "pork", "chicken", "fish", "vegetarian", "tofu"] as const;
export const APPLIANCES = ["microwave", "hob", "oven", "air_fryer", "mixer", "slow_cooker",
  "pressure_cooker", "barbecue"] as const;
export const DIFFICULTIES = ["easy", "medium", "hard"] as const;
export const TIER_IDS = ["light", "regular"] as const;
export const CUISINES = ["italian", "french", "spanish", "portuguese", "greek", "british", "german",
  "scandinavian", "eastern_european", "turkish", "lebanese", "moroccan", "persian", "ethiopian",
  "west_african", "chinese", "japanese", "korean", "thai", "vietnamese", "filipino", "indonesian",
  "indian", "american", "southern_us", "tex_mex", "mexican", "caribbean", "brazilian", "peruvian",
  "latin_american", "australian", "fusion", "international"] as const;
export const SUITABLE_KEYS = ["vegetarian", "vegan", "pescatarian", "halal", "gluten_free", "lactose_free",
  "nut_free", "egg_free", "shellfish_free", "sesame_free", "soy_free"] as const;

/** Spoonacular (RapidAPI) host, same as functions/src/index.ts. */
export const SPOONACULAR_HOST = "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com";
