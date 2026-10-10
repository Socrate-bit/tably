import {env, SPOONACULAR_HOST} from "./config.js";

/** GET with the RapidAPI headers, retrying twice on 429 (ported from functions/src/index.ts). */
async function rapidGet(url: string): Promise<Response> {
  if (!env.spoonacularKey) throw new Error("SPOONACULAR_API_KEY is not set (pipeline/.env)");
  for (let attempt = 1; ; attempt++) {
    const response = await fetch(url, {
      headers: {"x-rapidapi-key": env.spoonacularKey, "x-rapidapi-host": SPOONACULAR_HOST},
      signal: AbortSignal.timeout(30_000),
    });
    if (response.status !== 429 || attempt === 3) return response;
    console.warn(`[spoonacular] rate limited, retrying (${attempt})`);
    await new Promise((resolve) => setTimeout(resolve, 1200 * attempt));
  }
}

export interface SeedQuery {
  query?: string;
  cuisine?: string;
  diet?: string;
  number: number;
  offset?: number;
}

/** Raw Spoonacular recipe as returned by complexSearch with full information. */
export type RawRecipe = Record<string, any> & {id: number};

/** Full-information main courses, randomly sorted (same fixed params as the app). */
export async function complexSearch(q: SeedQuery): Promise<{results: RawRecipe[]; totalResults: number; remaining: string | null}> {
  const params = new URLSearchParams({
    type: "main course",
    instructionsRequired: "true",
    addRecipeInformation: "true",
    addRecipeNutrition: "true",
    fillIngredients: "true",
    sort: "random",
    number: String(Math.min(100, q.number)),
  });
  if (q.query) params.set("query", q.query);
  if (q.cuisine) params.set("cuisine", q.cuisine);
  if (q.diet) params.set("diet", q.diet);
  if (q.offset) params.set("offset", String(q.offset));

  const response = await rapidGet(`https://${SPOONACULAR_HOST}/recipes/complexSearch?${params}`);
  if (!response.ok) throw new Error(`[spoonacular] complexSearch ${response.status}: ${(await response.text()).slice(0, 300)}`);
  const body = (await response.json()) as {results?: RawRecipe[]; totalResults?: number};
  return {
    results: body.results ?? [],
    totalResults: body.totalResults ?? 0,
    remaining: response.headers.get("x-ratelimit-requests-remaining"),
  };
}

/** The parts of a raw recipe the clean prompt needs. */
export function summariseRaw(r: RawRecipe): Record<string, unknown> {
  const steps: any[] = (r.analyzedInstructions ?? []).flatMap((a: any) => a.steps ?? []);
  return {
    title: r.title,
    servings: r.servings,
    readyInMinutes: r.readyInMinutes,
    cuisines: r.cuisines ?? [],
    dishTypes: r.dishTypes ?? [],
    ingredients: (r.extendedIngredients ?? []).map((i: any) => ({
      original: i.original,
      name: i.nameClean || i.name,
      metric: i.measures?.metric ? {amount: i.measures.metric.amount, unit: i.measures.metric.unitShort} : null,
    })),
    steps: steps.map((s) => String(s.step ?? "").trim()).filter(Boolean),
    // Some recipes only have a free-text instructions blob; the LLM can still work from it.
    instructionsText: steps.length ? undefined : (typeof r.instructions === "string" ? r.instructions.replace(/<[^>]+>/g, " ") : undefined),
    equipment: [...new Set<string>(steps.flatMap((s) => (s.equipment ?? []).map((e: any) => String(e.name))))],
  };
}
