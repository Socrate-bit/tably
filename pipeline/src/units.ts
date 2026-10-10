import {COUNT_UNITS, VOLUME_UNITS, WEIGHT_UNITS} from "./config.js";
import type {MasterIngredient, Unit} from "./schema.js";

export const isWeight = (u: Unit): boolean => (WEIGHT_UNITS as readonly string[]).includes(u);
export const isVolume = (u: Unit): boolean => (VOLUME_UNITS as readonly string[]).includes(u);
export const isCount = (u: Unit): boolean => (COUNT_UNITS as readonly string[]).includes(u);

/** Millilitres in one unit of volume. */
const ML_PER_UNIT: Partial<Record<Unit, number>> = {ml: 1, cl: 10, l: 1000, tsp: 5, tbsp: 15};

export interface GramsResult {
  grams: number;
  basis: "weight" | "volume" | "count" | "none";
}

/**
 * Convert an amount of an ingredient to grams using the master row.
 * Returns null when the row lacks the conversion (caller flags for review).
 */
export function toGrams(amount: number, unit: Unit, row: MasterIngredient): GramsResult | null {
  if (unit === "to_taste") return {grams: 0, basis: "none"};
  if (unit === "pinch") return {grams: 0.3, basis: "none"};
  if (unit === "g") return {grams: amount, basis: "weight"};
  if (unit === "kg") return {grams: amount * 1000, basis: "weight"};
  // Spoon measures of dense things (spices, flour) may have a specific weight.
  const perUnit = row.gramsPerUnit[unit];
  if (isCount(unit) || ((unit === "tsp" || unit === "tbsp") && perUnit)) {
    return perUnit ? {grams: amount * perUnit, basis: "count"} : null;
  }
  if (isVolume(unit)) {
    return {grams: amount * (ML_PER_UNIT[unit] ?? 0) * (row.densityGPerMl ?? 1), basis: "volume"};
  }
  return null;
}

/** Round a per-portion amount to a step a cook would actually measure. */
export function roundAmount(amount: number, unit: Unit): number {
  if (unit === "to_taste" || unit === "pinch") return Math.max(1, Math.round(amount));
  if (unit === "g" || unit === "ml") {
    if (amount < 10) return roundTo(amount, 0.5);
    if (amount < 50) return roundTo(amount, 1);
    if (amount < 200) return roundTo(amount, 5);
    return roundTo(amount, 10);
  }
  if (unit === "kg" || unit === "l") return roundTo(amount, 0.05);
  if (unit === "cl") return roundTo(amount, 0.5);
  if (unit === "tsp" || unit === "tbsp") return Math.max(0.25, roundTo(amount, 0.25));
  return Math.max(0.5, roundTo(amount, 0.5));
}

export function roundTo(value: number, step: number): number {
  return Number((Math.round(value / step) * step).toFixed(3));
}

export function round(value: number, decimals = 1): number {
  const f = 10 ** decimals;
  return Math.round(value * f) / f;
}
