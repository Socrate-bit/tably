import {parse} from "csv-parse/sync";
import {existsSync, readFileSync} from "node:fs";
import {PATHS} from "./config.js";
import {normaliseText} from "./text.js";

/** One row of data/ingredient_prices.csv, normalised to €/kg. */
export interface PriceRow {
  id: string;
  names: string[];
  pricePerKg: number;
  source: string;
}

let rows: PriceRow[] | undefined;

/**
 * Load the price CSV once. `per_unit` rows are converted with their
 * `grams_per_unit`; `per_l` rows are taken as €/kg (density ≈ 1 for the
 * liquids in the file: milk, stock, cream, juice).
 */
export function priceTable(): PriceRow[] {
  if (rows) return rows;
  rows = [];
  if (!existsSync(PATHS.prices)) return rows;
  const records = parse(readFileSync(PATHS.prices, "utf8"), {columns: true, skip_empty_lines: true}) as Record<string, string>[];
  for (const r of records) {
    const price = Number(r.price_eur);
    if (!Number.isFinite(price) || price <= 0) continue;
    let pricePerKg: number;
    if (r.price_basis === "per_unit") {
      const grams = Number(r.grams_per_unit);
      if (!grams) continue;
      pricePerKg = (price / grams) * 1000;
    } else {
      pricePerKg = price;
    }
    rows.push({
      id: r.id,
      names: [r.id.replace(/_/g, " "), r.name_fr, r.name_en].filter(Boolean),
      pricePerKg: Math.round(pricePerKg * 100) / 100,
      source: r.source,
    });
  }
  return rows;
}

/** Price whose fr/en/id name equals one of the given names (accent- and case-insensitive). */
export function findPrice(names: string[]): PriceRow | undefined {
  const keys = new Set(names.map(normaliseText).filter(Boolean));
  return priceTable().find((row) => row.names.some((n) => keys.has(normaliseText(n))));
}
