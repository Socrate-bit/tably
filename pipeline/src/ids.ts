import {createHash} from "node:crypto";

/** Stable catalogue id for a Spoonacular recipe, so every stage is re-runnable. */
export function recipeId(sourceId: number): string {
  return "r_" + createHash("sha1").update(`spoon:${sourceId}`).digest("hex").slice(0, 8);
}

/** Run `fn` over `items` with at most `limit` in flight. */
export async function mapLimit<T, R>(items: T[], limit: number, fn: (item: T) => Promise<R>): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let next = 0;
  async function worker(): Promise<void> {
    while (next < items.length) {
      const index = next++;
      results[index] = await fn(items[index]);
    }
  }
  await Promise.all(Array.from({length: Math.min(limit, items.length)}, worker));
  return results;
}
