/** Lowercase, strip accents and punctuation, collapse spaces. */
export function normaliseText(text: string): string {
  return text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

const STOPWORDS = new Set(("the a an of with and in on for to style easy quick best simple homemade classic alla al " +
  "de la le les des du au aux et a en un une avec pour facile rapide maison façon facon").split(" "));

/** Sorted content tokens of a title, so word order and filler don't matter. */
export function titleKey(title: string): string {
  return normaliseText(title).split(" ").filter((t) => t && !STOPWORDS.has(t)).sort().join(" ");
}

/** kebab-case slug for master ingredient ids. */
export function slugify(text: string): string {
  return normaliseText(text).replace(/ /g, "-");
}

/** Lowercase, accent-free search keywords (unique, non-empty). */
export function keywordsOf(...texts: string[]): string[] {
  return [...new Set(texts.flatMap((t) => normaliseText(t).split(" ")).filter((t) => t.length > 2 && !STOPWORDS.has(t)))];
}

/** Jaccard similarity of two sets. */
export function jaccard(a: Iterable<string>, b: Iterable<string>): number {
  const sa = new Set(a);
  const sb = new Set(b);
  if (sa.size === 0 && sb.size === 0) return 0;
  let inter = 0;
  for (const x of sa) if (sb.has(x)) inter++;
  return inter / (sa.size + sb.size - inter);
}
