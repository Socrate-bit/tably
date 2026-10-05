import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

/** Deployed next to the eur3 Firestore instance; the client must match. */
const REGION = "europe-west1";

/** RapidAPI key for Spoonacular, set with `firebase functions:secrets:set`. */
const spoonacularKey = defineSecret("SPOONACULAR_API_KEY");

/** The only grants a referral code may hand out. */
const GRANTABLE_TYPES = ["admin", "ugc"];

/**
 * Atomically redeems a referral code. Codes are the document id, uppercased,
 * so they are case-insensitive for the user:
 * 1. Validates the code exists with required fields (type, numUse, maxUse)
 * 2. Checks the type is grantable and the code is not exhausted
 * 3. Checks the caller hasn't already used this code
 * 4. Increments numUse, appends the uid to usedBy
 * 5. Sets userType on the user document — the only writer of that field
 */
export const redeemReferralCode = onCall({region: REGION}, async (request) => {
  // Require authentication — Tably signs in anonymously before any UI renders.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const uid = request.auth.uid;
  const code = request.data?.code;
  if (typeof code !== "string" || code.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A referral code is required.");
  }

  const codeRef = db.collection("referralCodes").doc(code.trim().toUpperCase());
  const userRef = db.collection("users").doc(uid);

  const userType = await db.runTransaction(async (tx) => {
    const codeSnap = await tx.get(codeRef);
    if (!codeSnap.exists) {
      throw new HttpsError("not-found", "Referral code does not exist.");
    }
    const data = codeSnap.data()!;
    const type = data.type as string | undefined;
    const numUse = data.numUse as number | undefined;
    const maxUse = data.maxUse as number | undefined;

    if (type === undefined || numUse === undefined || maxUse === undefined) {
      throw new HttpsError("failed-precondition", "Invalid referral code.");
    }
    // A typo'd type would otherwise burn a use and grant nothing.
    if (!GRANTABLE_TYPES.includes(type)) {
      throw new HttpsError("failed-precondition", "Invalid referral code.");
    }
    if (numUse >= maxUse) {
      throw new HttpsError(
        "resource-exhausted",
        "This code has reached its usage limit."
      );
    }
    const usedBy = (data.usedBy as string[]) || [];
    if (usedBy.includes(uid)) {
      throw new HttpsError(
        "already-exists",
        "You have already used this code."
      );
    }

    // Atomic updates
    tx.update(codeRef, {
      numUse: FieldValue.increment(1),
      usedBy: FieldValue.arrayUnion(uid),
    });
    // merge:true so redeeming before onboarding finishes creates the document
    // without clobbering the profile written later.
    tx.set(userRef, {userType: type}, {merge: true});

    return type;
  });

  return {userType};
});

const SPOONACULAR_HOST = "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com";

/** Candidates fetched when the caller doesn't say; Spoonacular's cap is 100. */
const SEARCH_SIZE = 24;
const MAX_SEARCH_SIZE = 100;

/** Spoonacular prices are US cents; everyone is on EUR for now. Approximate. */
const USD_TO_EUR = 0.86;

/** Profile diet ids → Spoonacular diets. Halal has none, see HALAL_EXCLUDES. */
const DIETS: Record<string, string> = {
  vegetarian: "vegetarian",
  vegan: "vegan",
  pescatarian: "pescetarian",
};
const HALAL_EXCLUDES = ["pork", "bacon", "ham", "wine", "beer"];

/** Profile allergy ids → Spoonacular intolerances. */
const INTOLERANCES: Record<string, string[]> = {
  gluten_free: ["Gluten"],
  lactose_free: ["Dairy"],
  nut_free: ["Peanut", "Tree Nut"],
  egg_free: ["Egg"],
  shellfish_free: ["Shellfish"],
  sesame_free: ["Sesame"],
  soy_free: ["Soy"],
};

/** Ingredients excluded when the user did not pick that protein. */
const PROTEIN_EXCLUDES: Record<string, string[]> = {
  beef: ["beef"],
  pork: ["pork", "bacon", "ham", "prosciutto", "pancetta", "chorizo"],
  chicken: ["chicken"],
  fish: ["fish", "salmon", "tuna", "cod"],
};

/** App cuisine ids → Spoonacular cuisines (comma means OR). */
const CUISINES: Record<string, string> = {
  italian: "Italian",
  asian: "Asian,Chinese,Japanese,Korean,Thai,Vietnamese",
  mexican: "Mexican,Latin American",
  indian: "Indian",
  mediterranean: "Mediterranean,Greek,Spanish,Middle Eastern",
};

/**
 * The cravings Spoonacular can filter on. The others ("family favourites",
 * "indulgent"…) are left to Gemini's classification.
 */
const CRAVINGS: Record<string, Record<string, string>> = {
  quick: {maxReadyTime: "25"},
  high_protein: {minProtein: "30"},
  low_calorie: {maxCalories: "450"},
};

/** Profile cook-time ids → Spoonacular maxReadyTime in minutes. */
const MAX_READY_TIME: Record<string, number> = {
  "15_30": 30,
  "30_45": 45,
  "45_60": 60,
};

/** Keeps only string items, so bad input can't reach the query. */
const stringList = (value: unknown): string[] =>
  Array.isArray(value) ? value.filter((v): v is string => typeof v === "string") : [];

const round = (value: number, decimals = 2): number =>
  Math.round(value * 10 ** decimals) / 10 ** decimals;

/** A non-empty string, or null. */
const text = (value: unknown): string | null =>
  typeof value === "string" && value.trim().length > 0 ? value.trim() : null;

/**
 * Builds the complexSearch query: the profile's hard constraints (diets,
 * allergies, proteins, cook time), then the optional search filters (text,
 * cuisines, one craving, one protein). Meat exclusions only apply when no
 * diet already rules meat out.
 */
function searchParams(data: Record<string, unknown>): URLSearchParams {
  const diets = stringList(data.diets);
  const allergies = stringList(data.allergies);
  const proteins = stringList(data.proteins);
  const cookTime = text(data.cookTime);
  const requested = Math.round(Number(data.number));
  const number = Number.isFinite(requested) ?
    Math.min(Math.max(requested, 1), MAX_SEARCH_SIZE) :
    SEARCH_SIZE;

  const diet = diets.map((d) => DIETS[d]).filter(Boolean);
  // A protein picked in the search filters narrows further.
  const protein = text(data.protein);
  if (protein === "vegetarian" && !diet.includes("vegan")) diet.push("vegetarian");
  const intolerances = allergies.flatMap((a) => INTOLERANCES[a] ?? []);
  const excludes = diets.includes("halal") ? [...HALAL_EXCLUDES] : [];
  // "no_meat" excludes every meat and fish; no meat ticked at all means no
  // preference; otherwise the meats not ticked are excluded.
  const noMeat = proteins.includes("no_meat");
  if (diet.length === 0 && (noMeat || proteins.length > 0)) {
    for (const [protein, names] of Object.entries(PROTEIN_EXCLUDES)) {
      if (noMeat || !proteins.includes(protein)) excludes.push(...names);
    }
  }

  const params = new URLSearchParams({
    type: "main course",
    instructionsRequired: "true",
    addRecipeInformation: "true",
    addRecipeNutrition: "true",
    fillIngredients: "true",
    sort: "random",
    number: String(number),
  });
  if (diet.length > 0) params.set("diet", [...new Set(diet)].join(","));
  if (intolerances.length > 0) params.set("intolerances", intolerances.join(","));
  if (excludes.length > 0) params.set("excludeIngredients", [...new Set(excludes)].join(","));
  const maxReadyTime = cookTime ? MAX_READY_TIME[cookTime] : undefined;
  if (maxReadyTime) params.set("maxReadyTime", String(maxReadyTime));

  // Search filters, all optional.
  const query = text(data.query);
  if (query) params.set("query", query.slice(0, 100));
  const cuisines = stringList(data.cuisines).map((c) => CUISINES[c]).filter(Boolean);
  if (cuisines.length > 0) params.set("cuisine", cuisines.join(","));
  const craving = text(data.craving);
  for (const [key, value] of Object.entries(craving ? CRAVINGS[craving] ?? {} : {})) {
    // A craving's time limit never loosens the profile's own.
    const current = params.get(key);
    params.set(key, current ? String(Math.min(Number(current), Number(value))) : value);
  }
  // Ingredients the user has ("what can I make with…"), most used first.
  const include = stringList(data.includeIngredients).map((i) => i.trim()).filter(Boolean);
  if (protein && protein !== "vegetarian") include.unshift(protein);
  if (include.length > 0) params.set("includeIngredients", include.join(",").slice(0, 200));
  if (stringList(data.includeIngredients).length > 0) params.set("sort", "max-used-ingredients");
  return params;
}

/**
 * Reduces a Spoonacular result to what the app and Gemini need (~26 KB → ~3 KB).
 * Ingredient amounts are per portion, prices are EUR per portion. Returns null
 * for results too thin to cook from.
 */
function trimRecipe(r: any, {requireImage = true} = {}): Record<string, unknown> | null {
  const servings = Math.max(1, Number(r.servings) || 1);
  const rawSteps: any[] = (r.analyzedInstructions ?? []).flatMap((a: any) => a.steps ?? []);
  const steps = rawSteps.map((s) => String(s.step ?? "").trim()).filter((s) => s.length > 0);
  if (steps.length < 2 || (requireImage && typeof r.image !== "string")) return null;

  const nutrient = (name: string): number =>
    Math.round(r.nutrition?.nutrients?.find((n: any) => n.name === name)?.amount ?? 0);
  const equipment = new Set<string>(
    rawSteps.flatMap((s) => (s.equipment ?? []).map((e: any) => String(e.name)))
  );

  return {
    id: r.id,
    title: r.title,
    // The largest size Spoonacular serves; the search returns a smaller one.
    image: typeof r.image === "string" ? r.image.replace(/-\d+x\d+\.(\w+)$/, "-636x393.$1") : "",
    readyInMinutes: r.readyInMinutes,
    price: round((Number(r.pricePerServing) || 0) / 100 * USD_TO_EUR),
    sourceName: r.sourceName ?? null,
    sourceUrl: r.sourceUrl ?? null,
    macros: {
      kcal: nutrient("Calories"),
      protein: nutrient("Protein"),
      carbs: nutrient("Carbohydrates"),
      fat: nutrient("Fat"),
    },
    ingredients: (r.extendedIngredients ?? []).map((i: any, index: number) => ({
      // A few ingredients have no id; a negative index keeps them distinct.
      id: typeof i.id === "number" ? i.id : -(index + 1),
      name: i.nameClean || i.name,
      aisle: i.aisle ?? null,
      amount: round((Number(i.measures?.metric?.amount) || 0) / servings),
      unit: i.measures?.metric?.unitShort ?? "",
    })),
    steps,
    equipment: [...equipment],
  };
}

/**
 * One Spoonacular GET through RapidAPI with the secret key. A spent quota
 * becomes "resource-exhausted", anything else "unavailable".
 */
async function spoonacularGet(path: string, params: URLSearchParams, uid: string): Promise<any> {
  const url = `https://${SPOONACULAR_HOST}${path}?${params}`;
  let response: Response;
  try {
    response = await fetch(url, {
      headers: {
        "x-rapidapi-key": spoonacularKey.value(),
        "x-rapidapi-host": SPOONACULAR_HOST,
      },
      signal: AbortSignal.timeout(30_000),
    });
  } catch (e) {
    logger.error(`spoonacular ${path}: request failed`, e);
    throw new HttpsError("unavailable", "Recipe search is unavailable.");
  }

  logger.info(`spoonacular ${path}: quota`, {
    uid,
    status: response.status,
    requestsRemaining: response.headers.get("x-ratelimit-requests-remaining"),
  });
  if (response.status === 402 || response.status === 429) {
    throw new HttpsError("resource-exhausted", "Recipe search quota reached.");
  }
  if (!response.ok) {
    logger.error(`spoonacular ${path}: bad status`, {status: response.status, body: await response.text()});
    throw new HttpsError("unavailable", "Recipe search is unavailable.");
  }
  return response.json();
}

/**
 * Searches Spoonacular for main courses matching the caller's constraints.
 * 1. Maps the constraints and search filters to query parameters
 * 2. Calls complexSearch with the secret RapidAPI key (1 request of the quota,
 *    for up to 100 recipes)
 * 3. Trims each result to the fields the app and Gemini use
 * Live and uncached: every call spends quota.
 */
export const searchRecipes = onCall(
  {region: REGION, secrets: [spoonacularKey], timeoutSeconds: 60},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    const body = await spoonacularGet("/recipes/complexSearch", searchParams(data), request.auth.uid);
    const recipes = (body.results ?? [])
      .map((r: any) => trimRecipe(r))
      .filter((r: unknown) => r !== null);
    logger.info("searchRecipes: done", {total: body.totalResults, returned: recipes.length});
    return {recipes};
  }
);

/** Spoonacular requests one user's AI chef may spend a day. The quota is shared by the whole app. */
const AGENT_DAILY_CAP = 10;

/** Recipes the AI chef asks for per search; it shows a handful at a time. */
const AGENT_SEARCH_SIZE = 8;

/**
 * Counts [requests] against the user's daily allowance for the AI chef, in
 * `agentQuota/{uid}` (server-only: the rules deny every client). Throws
 * "resource-exhausted" once the day's cap is reached.
 */
async function chargeAgentQuota(uid: string, requests: number): Promise<void> {
  const ref = db.collection("agentQuota").doc(uid);
  const day = new Date().toISOString().slice(0, 10);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = snap.data()?.day === day ? Number(snap.data()?.count) || 0 : 0;
    if (count + requests > AGENT_DAILY_CAP) {
      throw new HttpsError("resource-exhausted", "Daily AI chef recipe quota reached.");
    }
    tx.set(ref, {day, count: count + requests});
  });
}

/** Full, trimmed recipes for Spoonacular ids (1 request). */
async function recipesById(ids: number[], uid: string): Promise<Record<string, unknown>[]> {
  if (ids.length === 0) return [];
  const params = new URLSearchParams({ids: ids.join(","), includeNutrition: "true"});
  const body = await spoonacularGet("/recipes/informationBulk", params, uid);
  return (Array.isArray(body) ? body : [])
    .map((r: any) => trimRecipe(r))
    .filter((r): r is Record<string, unknown> => r !== null);
}

/**
 * A stable positive id for a recipe imported from [url] that Spoonacular
 * gave none, so re-importing the same page finds the same recipe.
 */
function importedId(url: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < url.length; i++) {
    hash ^= url.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return 900_000_000 + (hash % 99_999_999);
}

/**
 * Everything the AI chef can ask Spoonacular, one action per call, each
 * capped per user per day (see AGENT_DAILY_CAP):
 * - search: complexSearch with the profile's constraints, plus
 *   includeIngredients for "what can I make with…" (1 request)
 * - similar: recipes like a Spoonacular id, in full (2 requests)
 * - extract: imports a recipe from a web page (1 request)
 * - substitutes: replacements for an English ingredient name (1 request)
 * - winePairing: wines for an English dish or ingredient (1 request)
 * Recipes come back trimmed, like searchRecipes.
 */
export const spoonacular = onCall(
  {region: REGION, secrets: [spoonacularKey], timeoutSeconds: 60},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const uid = request.auth.uid;
    const data = (request.data ?? {}) as Record<string, unknown>;
    const action = text(data.action);

    switch (action) {
    case "search": {
      await chargeAgentQuota(uid, 1);
      const params = searchParams({number: AGENT_SEARCH_SIZE, ...data});
      const body = await spoonacularGet("/recipes/complexSearch", params, uid);
      const recipes = (body.results ?? []).map((r: any) => trimRecipe(r)).filter((r: unknown) => r !== null);
      logger.info("spoonacular search: done", {uid, returned: recipes.length});
      return {recipes};
    }
    case "similar": {
      const id = Math.round(Number(data.id));
      if (!Number.isFinite(id) || id <= 0) throw new HttpsError("invalid-argument", "A Spoonacular id is required.");
      await chargeAgentQuota(uid, 2);
      const similar = await spoonacularGet(`/recipes/${id}/similar`, new URLSearchParams({number: "6"}), uid);
      const ids = (Array.isArray(similar) ? similar : []).map((r: any) => Number(r.id)).filter((i) => i > 0);
      return {recipes: await recipesById(ids, uid)};
    }
    case "extract": {
      const url = text(data.url);
      if (!url || !/^https?:\/\//i.test(url)) throw new HttpsError("invalid-argument", "A web address is required.");
      await chargeAgentQuota(uid, 1);
      const params = new URLSearchParams({url, analyze: "true", forceExtraction: "true", includeNutrition: "true"});
      const raw = await spoonacularGet("/recipes/extract", params, uid);
      const recipe = trimRecipe(raw, {requireImage: false});
      if (recipe === null) return {recipes: []};
      // Pages Spoonacular doesn't know get no id; the app needs a positive one.
      if (!(Number(recipe.id) > 0)) recipe.id = importedId(url);
      return {recipes: [recipe]};
    }
    case "substitutes": {
      const ingredient = text(data.ingredient);
      if (!ingredient) throw new HttpsError("invalid-argument", "An ingredient is required.");
      await chargeAgentQuota(uid, 1);
      const params = new URLSearchParams({ingredientName: ingredient.slice(0, 60)});
      const body = await spoonacularGet("/food/ingredients/substitutes", params, uid);
      return {substitutes: stringList(body.substitutes), message: text(body.message) ?? ""};
    }
    case "winePairing": {
      const food = text(data.food);
      if (!food) throw new HttpsError("invalid-argument", "A dish or ingredient is required.");
      await chargeAgentQuota(uid, 1);
      const params = new URLSearchParams({food: food.slice(0, 60)});
      const maxPrice = Number(data.maxPrice);
      if (Number.isFinite(maxPrice) && maxPrice > 0) params.set("maxPrice", String(Math.round(maxPrice)));
      const body = await spoonacularGet("/food/wine/pairing", params, uid);
      return {
        wines: stringList(body.pairedWines),
        text: text(body.pairingText) ?? "",
        products: (body.productMatches ?? []).slice(0, 3).map((p: any) => ({title: String(p.title ?? ""), price: String(p.price ?? "")})),
      };
    }
    default:
      throw new HttpsError("invalid-argument", `Unknown action: ${action}`);
    }
  }
);
