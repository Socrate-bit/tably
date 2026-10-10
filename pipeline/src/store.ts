import {existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync} from "node:fs";
import {dirname, join} from "node:path";
import {PATHS} from "./config.js";

/** Read a JSON file, or return `fallback` when it does not exist. */
export function readJson<T>(path: string, fallback?: T): T {
  if (!existsSync(path)) {
    if (fallback !== undefined) return fallback;
    throw new Error(`Missing file ${path}`);
  }
  return JSON.parse(readFileSync(path, "utf8")) as T;
}

/** Write pretty JSON, creating parent folders. */
export function writeJson(path: string, value: unknown): void {
  mkdirSync(dirname(path), {recursive: true});
  writeFileSync(path, JSON.stringify(value, null, 2) + "\n");
}

export function batchDir(batch: string): string {
  return join(PATHS.work, batch);
}

/** work/<batch>/<stage>/<id>.json */
export function stagePath(batch: string, stage: string, id: string): string {
  return join(batchDir(batch), stage, `${id}.json`);
}

export function readStage<T>(batch: string, stage: string, id: string): T {
  return readJson<T>(stagePath(batch, stage, id));
}

export function hasStage(batch: string, stage: string, id: string): boolean {
  return existsSync(stagePath(batch, stage, id));
}

export function writeStage(batch: string, stage: string, id: string, value: unknown): void {
  writeJson(stagePath(batch, stage, id), value);
}

/** Ids that have an output file for `stage`, sorted for determinism. */
export function stageIds(batch: string, stage: string): string[] {
  const dir = join(batchDir(batch), stage);
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter((f) => f.endsWith(".json")).map((f) => f.slice(0, -5)).sort();
}

/** Load prompts/<name>.md as the system instruction of an LLM stage. */
export function loadPrompt(name: string): string {
  return readFileSync(join(PATHS.prompts, `${name}.md`), "utf8");
}

/** Fill {{key}} placeholders in a prompt template. */
export function fillTemplate(template: string, values: Record<string, string>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_, key: string) => values[key] ?? "");
}
