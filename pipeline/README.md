# Tably recipe pipeline

Offline ingest that turns scraped recipes into the shared catalogue
(`recipes/{id}`, `ingredients/{slug}` in Firestore, photos in Storage).
Every stage caches its output under `work/<batch>/<stage>/<id>.json`, so a
re-run only redoes what is missing (or everything with `--force`).

```
raw (seed) → clean → map → nutrition → balance → portion → tag → price → check → dedupe → photo → final → upload
```

| Stage | LLM | What it does |
|---|---|---|
| seed | – | Spoonacular `complexSearch`, skips ids in `work/seen.json` |
| clean | 3.5-flash | Complete/coherent steps, tidy ingredient list, allowed units, fr + en text. Whole-dish amounts. |
| map | 3.5-flash (unknowns only) | Links each line to `data/ingredients.json`; proposes new rows (`pending`) with a CIQUAL code; converts to grams |
| nutrition | – | Σ grams × CIQUAL per 100 g → dish totals, energy density → `tier` (light < 110 kcal/100 g) |
| balance | 3.5-flash (when a floor fails) | Protein / fat-share / vegetables / starch floors per tier; minimal rewrite, re-mapped once |
| portion | – | Picks `servings` so kcal/portion sits in the tier band; rounds per-portion amounts |
| tag | 3.5-flash | Times, difficulty, craving, protein, cuisine, appliances, keywords; computed diet/allergen flags (LLM may only switch a flag off) |
| price | – | Σ grams × €/kg from the master table |
| check | 3.5-pro | Final LLM reviewer: approve / reject with notes and a 1–10 score (replaces the human gate) |
| dedupe | 3.1-flash-lite (candidates only) | Same source id / same title key / ingredient Jaccard ≥ 0.75 → LLM "same dish?" |
| photo | Nano Banana 2 Lite (Batch API) + 3.1-flash-lite | One batch job per round for the whole batch (square 1K) → Gemini vision check → rejected ones go into the next round (≤ 3); hero 1024², thumb 400², blurhash |
| final | – | Builds and validates the Firestore document |

Prompts live in `prompts/*.md` and are loaded at runtime: edit, then re-run the
stage with `--force`.

## Setup

```sh
cd pipeline
npm install
cp .env.example .env        # fill SPOONACULAR_API_KEY and GEMINI_API_KEY
# CIQUAL 2020 (once): https://ciqual.anses.fr/cms/sites/default/files/inline-files/XML_2020_07_07.zip
unzip XML_2020_07_07.zip -d /tmp/ciqual && npm run import-ciqual -- --dir /tmp/ciqual
cp ~/wherever/ingredient_prices.csv data/ && npm run import-prices
```

## The 10-recipe test loop

```sh
npm run seed   -- --batch b1 --limit 10            # 1 Spoonacular request
npm run run    -- --batch b1 --to price            # everything except photos
npm run report -- --batch b1                       # read this, fix prompts
npm run run    -- --batch b1 --stage clean --force --only r_xxxxxxxx   # redo one recipe, one stage
npm run run    -- --batch b1 --from balance --force                     # redo from a stage
npm run review-ingredients                         # list pending master rows
npm run review-ingredients -- --approve onion,garlic
npm run run    -- --batch b1 --from photo          # PHOTO_MODE=batch (default) or live
npm run pull-index                                 # published recipes for dedupe (needs Firebase auth)
npm run upload -- --batch b1                       # dry run
npm run upload -- --batch b1 --apply
```

Firebase auth for `pull-index` / `upload`: Application Default Credentials
(`gcloud auth login --update-adc`) or `GOOGLE_APPLICATION_CREDENTIALS` in `.env`.

## Files

- `data/ingredients.json` — master ingredient table (committed). Rows the LLM proposes
  start as `pending`; approve them after a look. `aliases` make future matches
  deterministic.
- `data/ciqual.json` — generated, per-100 g kcal/protein/carbs/fat/fiber/salt/sugars.
- `data/ingredient_prices.csv` — €/kg source; merged with `import-prices`.
- `work/` (gitignored) — stage outputs, `errors.json` per batch, photos, `seen.json`,
  `published-index.json`.

## Rules baked in (see `src/config.ts`)

- Tiers: light 350–500 kcal/portion (target 425), regular 550–800 (target 650).
- Floors per portion — light: protein ≥ 20 g, fat ≤ 35 % kcal, veg ≥ 200 g;
  regular: protein ≥ 25 g, fat ≤ 40 %, veg ≥ 150 g, carbs ≥ 30 g. Indulgent-style
  dishes are exempt from the fat cap.
- Units: `g kg ml cl l tsp tbsp piece clove slice bunch sprig leaf stalk head can jar pack cube handful pinch to_taste`.
- A recipe becomes `draft` (not published) when it `needsReview` or is a duplicate.

## Running the text stages with Claude Code instead of Gemini

Set `LLM_BACKEND=files` in `.env`. Every LLM call then writes a request file to
`work/llm/requests/` (system prompt, input, JSON schema, `tier`: haiku / sonnet / opus)
and the stage reports "waiting". Answers go to `work/llm/responses/` and are validated
on the next run. Images still use Gemini (`GEMINI_API_KEY` stays required).

In a Claude Code session opened in this folder, paste:

> Drive the pipeline: loop { run `npm run run -- --batch b1 --from clean --to final`;
> if a stage is waiting, answer every open request listed by `npm run pipeline -- requests`
> (read the file, follow `system`, produce one JSON object matching `schema`, write it to
> `responsePath`; use a subagent of the request's `tier`); repeat } until `final` reports
> 0 waiting. Then `npm run report -- --batch b1` and `npm run pipeline -- review --batch b1`.

Tiers map to stages: sonnet = clean, balance, fix, ingredient proposals, price research;
opus = check (reviewer) and ingredient verification; haiku = tag, CIQUAL/USDA picks,
dedupe confirm, photo check. Switch back to the API with `LLM_BACKEND=gemini`.

## Review UI

`npm run pipeline -- review --batch b1` serves http://localhost:8787: one recipe per
page (← → keys), source vs. result with photos, macros, price, tags, diet flags, the
reviewer's verdict and notes, every pipeline stage's changes, and automatic warnings.

## Variants (light ↔ regular twins)

After `check`, the `variants` stage asks for the other version of every approved
recipe where it is relevant (a stew over rice gets a light twin without the rice and
with more vegetables; a grilled fish with vegetables gets a hearty twin with a starch).
Pizza, pasta dishes, sandwiches, composed salads get none. The twin is kept only if its
computed numbers land in the target band; it is injected at `clean` as `<id>-light` or
`<id>-full` with `variantOf`, and runs through the normal chain on the next `run`
(the driver loop does this automatically). `final` links both ways (`variantOf`,
`variantId`) so the app can offer "normal / léger" on one recipe page.
