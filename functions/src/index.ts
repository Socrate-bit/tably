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

/**
 * Searches per UTC day: admins and creators (a granted userType) get more.
 * The app shows the same numbers.
 */
const DAILY_SEARCH_LIMIT = 30;
const GRANTED_SEARCH_LIMIT = 200;

/** Today's UTC date, "YYYY-MM-DD": the quota resets at midnight UTC. */
const utcDay = (): string => new Date().toISOString().slice(0, 10);

/**
 * Spends one of the caller's daily searches at `searchQuota/{uid}` (server
 * only, so the client can't reset it). The limit follows the user's type.
 * Returns the searches left, or throws resource-exhausted once the day's
 * are spent.
 */
async function spendSearch(uid: string, day: string): Promise<number> {
  const ref = db.collection("searchQuota").doc(uid);
  const userRef = db.collection("users").doc(uid);
  return db.runTransaction(async (tx) => {
    const [quota, user] = await Promise.all([tx.get(ref), tx.get(userRef)]);
    const limit = GRANTABLE_TYPES.includes(user.data()?.userType) ? GRANTED_SEARCH_LIMIT : DAILY_SEARCH_LIMIT;
    const data = quota.data();
    const count = data?.day === day ? Number(data.count) || 0 : 0;
    if (count >= limit) {
      throw new HttpsError("resource-exhausted", "Daily search limit reached.", {reason: "daily-limit"});
    }
    tx.set(ref, {day, count: count + 1});
    return limit - count - 1;
  });
}

/** Gives back a search whose Spoonacular call failed, unless the day rolled over. */
async function refundSearch(uid: string, day: string): Promise<void> {
  const ref = db.collection("searchQuota").doc(uid);
  try {
    await db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      if (data?.day === day && Number(data.count) > 0) tx.update(ref, {count: FieldValue.increment(-1)});
    });
  } catch (e) {
    logger.error("searchRecipes: refund failed", e);
  }
}

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

/** Onboarding cook-time ids → maxReadyTime, for app builds that send them. */
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
  // The profile's time limit in minutes; older builds send the onboarding id.
  const minutes = Math.round(Number(data.maxReadyTime));
  const cookTime = text(data.cookTime);
  const maxReadyTime = Number.isFinite(minutes) && minutes > 0 ?
    minutes :
    cookTime ? MAX_READY_TIME[cookTime] : undefined;
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
  if (protein && protein !== "vegetarian") params.set("includeIngredients", protein);
  return params;
}

/**
 * Reduces a Spoonacular result to what the app and Gemini need (~26 KB → ~3 KB).
 * Ingredient amounts are per portion, prices are EUR per portion. Returns null
 * for results too thin to cook from.
 */
function trimRecipe(r: any): Record<string, unknown> | null {
  const servings = Math.max(1, Number(r.servings) || 1);
  const rawSteps: any[] = (r.analyzedInstructions ?? []).flatMap((a: any) => a.steps ?? []);
  const steps = rawSteps.map((s) => String(s.step ?? "").trim()).filter((s) => s.length > 0);
  if (typeof r.image !== "string" || steps.length < 2) return null;

  const nutrient = (name: string): number =>
    Math.round(r.nutrition?.nutrients?.find((n: any) => n.name === name)?.amount ?? 0);
  const equipment = new Set<string>(
    rawSteps.flatMap((s) => (s.equipment ?? []).map((e: any) => String(e.name)))
  );

  return {
    id: r.id,
    title: r.title,
    // The largest size Spoonacular serves; the search returns a smaller one.
    image: r.image.replace(/-\d+x\d+\.(\w+)$/, "-636x393.$1"),
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

/** One complexSearch call, trimmed; a network failure reads as status 0. */
async function complexSearch(
  params: URLSearchParams,
  uid: string,
  userSearchesLeft: number,
): Promise<{ok: boolean; status: number; body?: string; total?: number; recipes: Record<string, unknown>[]}> {
  let response: Response;
  try {
    response = await fetch(`https://${SPOONACULAR_HOST}/recipes/complexSearch?${params}`, {
      headers: {
        "x-rapidapi-key": spoonacularKey.value(),
        "x-rapidapi-host": SPOONACULAR_HOST,
      },
      signal: AbortSignal.timeout(30_000),
    });
  } catch (e) {
    logger.error("searchRecipes: request failed", e);
    return {ok: false, status: 0, recipes: []};
  }
  logger.info("searchRecipes: quota", {
    uid,
    status: response.status,
    userSearchesLeft,
    requestsRemaining: response.headers.get("x-ratelimit-requests-remaining"),
  });
  if (!response.ok) return {ok: false, status: response.status, body: await response.text(), recipes: []};
  const body = await response.json();
  const recipes = (body.results ?? [])
    .map(trimRecipe)
    .filter((r: unknown): r is Record<string, unknown> => r !== null);
  return {ok: true, status: response.status, total: body.totalResults, recipes};
}

/**
 * Searches Spoonacular for main courses matching the caller's constraints.
 * 1. Maps the constraints and search filters to query parameters
 * 2. Spends one of the caller's searches for today (30, or 200 for admins
 *    and creators)
 * 3. Calls complexSearch with the secret RapidAPI key (1 request of the quota,
 *    for up to 100 recipes); a failed call gives the search back. A wish
 *    from the custom instructions is searched first, and topped up with a
 *    second plain request when it finds too few
 * 4. Trims each result to the fields the app and Gemini use
 * Live and uncached: every call spends quota.
 */
export const searchRecipes = onCall(
  {region: REGION, secrets: [spoonacularKey], timeoutSeconds: 60},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const uid = request.auth.uid;
    const data = (request.data ?? {}) as Record<string, unknown>;
    const params = searchParams(data);
    // The custom instructions' wish, searched first when there's no query.
    const wish = params.has("query") ? null : text(data.wish);
    const day = utcDay();
    const left = await spendSearch(uid, day);

    const first = new URLSearchParams(params);
    if (wish) first.set("query", wish.slice(0, 100));
    const response = await complexSearch(first, uid, left);
    if (!response.ok) await refundSearch(uid, day);
    if (response.status === 402 || response.status === 429) {
      throw new HttpsError("resource-exhausted", "Recipe search quota reached.");
    }
    if (!response.ok) {
      logger.error("searchRecipes: bad status", {status: response.status, body: response.body});
      throw new HttpsError("unavailable", "Recipe search is unavailable.");
    }
    const recipes = response.recipes;

    // A wish that matched too few recipes is topped up with plain results.
    // A failed top-up keeps what the wish found.
    const number = Number(params.get("number"));
    // Thin results trimmed away don't count, so this only fires when
    // Spoonacular itself ran short.
    if (wish && (response.total ?? 0) < number) {
      const rest = new URLSearchParams(params);
      rest.set("number", String(number - recipes.length));
      const top = await complexSearch(rest, uid, left);
      const seen = new Set(recipes.map((r) => r.id));
      recipes.push(...top.recipes.filter((r) => !seen.has(r.id)));
    }
    logger.info("searchRecipes: done", {wish, total: response.total, returned: recipes.length});
    return {recipes};
  }
);
