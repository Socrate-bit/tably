import {GoogleGenAI, type Part} from "@google/genai";
import {createHash} from "node:crypto";
import {existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync} from "node:fs";
import {join} from "node:path";
import {z} from "zod";
import {env, LLM_CONCURRENCY, PATHS} from "./config.js";

// ---------------------------------------------------------------------------
// "files" backend: requests are written to disk and answered by Claude Code
// subagents; the next run picks the answers up. A stage that still waits on an
// answer throws PendingLLM, which the runner reports instead of logging an error.
// ---------------------------------------------------------------------------

export class PendingLLM extends Error {
  constructor(public requestPath: string) {
    super(`waiting for LLM answer: ${requestPath}`);
  }
}

/** Claude tier a Gemini model maps to in files mode. */
function tierOf(model: string): "opus" | "sonnet" | "haiku" {
  const tier = model.replace(/^claude:/, "");
  return tier === "opus" || tier === "haiku" ? tier : "sonnet";
}

function requestKey(parts: unknown[]): string {
  return createHash("sha1").update(JSON.stringify(parts)).digest("hex").slice(0, 16);
}

/**
 * Look for an answer file; if absent, write the request and signal pending.
 * `validate` turns the raw answer into T or throws; a bad answer is deleted and
 * its error stored on the request so the next subagent can fix it.
 */
function viaFiles<T>(label: string, request: Record<string, unknown>, validate: (raw: unknown) => T): T {
  const key = requestKey([request.system, request.input, request.schema, request.prompt, request.images]);
  const name = `${label.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}__${key}.json`;
  const requestPath = join(PATHS.llmRequests, name);
  const responsePath = join(PATHS.llmResponses, name);
  mkdirSync(PATHS.llmRequests, {recursive: true});
  mkdirSync(PATHS.llmResponses, {recursive: true});
  if (existsSync(responsePath)) {
    try {
      const result = validate(JSON.parse(readFileSync(responsePath, "utf8")));
      if (existsSync(requestPath)) unlinkSync(requestPath);
      return result;
    } catch (error) {
      unlinkSync(responsePath);
      request = {...request, feedback: `Your previous answer was rejected: ${(error as Error).message}. Answer again, following the schema exactly.`};
      console.warn(`[llm] ${label}: answer rejected, re-queued`);
    }
  }
  if (!existsSync(requestPath) || request.feedback) {
    writeFileSync(requestPath, JSON.stringify({label, responsePath, ...request}, null, 2));
  }
  throw new PendingLLM(requestPath);
}

let client: GoogleGenAI | undefined;
function ai(): GoogleGenAI {
  if (!env.geminiKey) throw new Error("GEMINI_API_KEY is not set (pipeline/.env)");
  return (client ??= new GoogleGenAI({apiKey: env.geminiKey}));
}

// Simple semaphore so a batch never has more than LLM_CONCURRENCY calls in flight.
let active = 0;
const queue: (() => void)[] = [];
async function withSlot<T>(fn: () => Promise<T>): Promise<T> {
  if (active >= LLM_CONCURRENCY) await new Promise<void>((resolve) => queue.push(resolve));
  active++;
  try {
    return await fn();
  } finally {
    active--;
    queue.shift()?.();
  }
}

function isRetryable(error: unknown): boolean {
  const message = String((error as Error)?.message ?? error);
  return /\b(429|500|502|503|504|RESOURCE_EXHAUSTED|UNAVAILABLE|overloaded|fetch failed)\b/i.test(message);
}

/** Retry on rate limits and server errors with exponential backoff. */
async function withRetry<T>(label: string, fn: () => Promise<T>, attempts = 5): Promise<T> {
  for (let attempt = 1; ; attempt++) {
    try {
      return await withSlot(fn);
    } catch (error) {
      if (attempt === attempts || !isRetryable(error)) throw error;
      const delay = 2 ** attempt * 1000 + Math.random() * 500;
      console.warn(`[llm] ${label}: retry ${attempt} in ${Math.round(delay)}ms (${(error as Error).message})`);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
}

/** Image bytes attached to a prompt. */
export interface ImageInput {
  data: Buffer;
  mimeType: string;
}

export interface JsonCallOptions<T> {
  model: string;
  /** System instruction (the stage prompt). */
  system: string;
  /** User content; objects are serialised as JSON. */
  input: unknown;
  schema: z.ZodType<T>;
  images?: ImageInput[];
  temperature?: number;
  label?: string;
}

/**
 * Structured-output call: the response must parse as `schema`. On a validation
 * failure the model is asked once more with the error appended.
 */
export async function jsonCall<T>(opts: JsonCallOptions<T>): Promise<T> {
  const label = opts.label ?? "json";
  const jsonSchema = z.toJSONSchema(opts.schema, {target: "openapi-3.0"});
  if (env.llmBackend === "files") {
    const images = (opts.images ?? []).map((image, i) => {
      const path = join(PATHS.llmRequests, `${label.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-img${i}.${image.mimeType.includes("png") ? "png" : "jpg"}`);
      mkdirSync(PATHS.llmRequests, {recursive: true});
      writeFileSync(path, image.data);
      return path;
    });
    return viaFiles(label, {tier: tierOf(opts.model), kind: "json", system: opts.system, input: opts.input, schema: jsonSchema, images},
      (raw) => {
        const result = opts.schema.safeParse(raw);
        if (!result.success) throw new Error(z.prettifyError(result.error));
        return result.data;
      });
  }
  const text = typeof opts.input === "string" ? opts.input : JSON.stringify(opts.input);
  const parts: Part[] = [
    ...(opts.images ?? []).map((image) => ({inlineData: {data: image.data.toString("base64"), mimeType: image.mimeType}})),
    {text},
  ];

  let feedback = "";
  for (let round = 1; round <= 2; round++) {
    const response = await withRetry(label, () => ai().models.generateContent({
      model: opts.model,
      contents: [{role: "user", parts: feedback ? [...parts, {text: feedback}] : parts}],
      config: {
        systemInstruction: opts.system,
        responseMimeType: "application/json",
        responseJsonSchema: jsonSchema,
        temperature: opts.temperature ?? 0.2,
      },
    }));
    const raw = response.text ?? "";
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      feedback = `Your previous answer was not valid JSON. Answer again with only the JSON object.`;
      console.warn(`[llm] ${label}: invalid JSON, asking again`);
      continue;
    }
    const result = opts.schema.safeParse(parsed);
    if (result.success) return result.data;
    feedback = `Your previous answer did not match the schema: ${z.prettifyError(result.error)}. Answer again.`;
    console.warn(`[llm] ${label}: schema mismatch, asking again`);
  }
  throw new Error(`[llm] ${label}: no valid answer after 2 rounds`);
}

// ---------------------------------------------------------------------------
// Image generation (Nano Banana): one live call, or one Batch API job for many.
// ---------------------------------------------------------------------------

const IMAGE_CONFIG = {responseModalities: ["IMAGE"], imageConfig: {aspectRatio: "1:1", imageSize: "1K"}};

function firstImage(response: {candidates?: {content?: {parts?: Part[]}}[]} | undefined): ImageInput | undefined {
  for (const part of response?.candidates?.[0]?.content?.parts ?? []) {
    if (part.inlineData?.data) {
      return {data: Buffer.from(part.inlineData.data, "base64"), mimeType: part.inlineData.mimeType ?? "image/png"};
    }
  }
  return undefined;
}

/** Generate one square image interactively. */
export async function imageCall(prompt: string, label: string): Promise<ImageInput> {
  const response = await withRetry(label, () => ai().models.generateContent({
    model: env.imageModel,
    contents: [{role: "user", parts: [{text: prompt}]}],
    config: IMAGE_CONFIG,
  }));
  const image = firstImage(response);
  if (!image) throw new Error(`[llm] ${label}: no image in response`);
  return image;
}

export type BatchOutcome = ImageInput | Error;

/**
 * Generate many images through the Batch API (half price, target 24 h). The
 * job name is handed back through `onCreated` so a caller can persist it and
 * resume with `existingJob` after a timeout. Results keep the input order.
 */
export async function imageBatch(prompts: string[], opts: {
  label: string;
  existingJob?: string;
  onCreated?: (jobName: string) => void;
  waitMinutes?: number;
}): Promise<BatchOutcome[]> {
  let job = opts.existingJob ?
    await ai().batches.get({name: opts.existingJob}) :
    await ai().batches.create({
      model: env.imageModel,
      src: prompts.map((prompt) => ({contents: [{role: "user", parts: [{text: prompt}]}], config: IMAGE_CONFIG})),
      config: {displayName: opts.label},
    });
  if (!opts.existingJob) opts.onCreated?.(job.name!);
  console.log(`[llm] ${opts.label}: batch ${job.name} ${job.state}`);

  const terminal = new Set(["JOB_STATE_SUCCEEDED", "JOB_STATE_FAILED", "JOB_STATE_CANCELLED", "JOB_STATE_EXPIRED"]);
  const deadline = Date.now() + (opts.waitMinutes ?? env.photoBatchWaitMinutes) * 60_000;
  while (!terminal.has(String(job.state))) {
    if (Date.now() > deadline) {
      throw new Error(`[llm] ${opts.label}: batch ${job.name} still ${job.state}; re-run later to resume`);
    }
    await new Promise((resolve) => setTimeout(resolve, 20_000));
    job = await ai().batches.get({name: job.name!});
    console.log(`[llm] ${opts.label}: ${job.state}`);
  }
  if (job.state !== "JOB_STATE_SUCCEEDED") {
    throw new Error(`[llm] ${opts.label}: batch ${job.name} ended ${job.state} ${JSON.stringify(job.error ?? "")}`);
  }
  const responses = job.dest?.inlinedResponses ?? [];
  return prompts.map((_, index) => {
    const item = responses[index];
    if (!item) return new Error("no response in batch output");
    if (item.error) return new Error(`batch item error: ${JSON.stringify(item.error)}`);
    return firstImage(item.response as any) ?? new Error("no image in batch response");
  });
}

/** Plain-text call, optionally grounded with Google Search (cannot be combined with JSON schema). */
export async function textCall(opts: {model: string; prompt: string; search?: boolean; label: string}): Promise<string> {
  if (env.llmBackend === "files") {
    return viaFiles(opts.label, {tier: tierOf(opts.model), kind: "text", prompt: opts.prompt, search: !!opts.search},
      (raw) => {
        if (typeof raw !== "string" && !(raw && typeof (raw as any).text === "string")) throw new Error("expected {\"text\": string}");
        return typeof raw === "string" ? raw : (raw as any).text;
      });
  }
  const response = await withRetry(opts.label, () => ai().models.generateContent({
    model: opts.model,
    contents: [{role: "user", parts: [{text: opts.prompt}]}],
    config: opts.search ? {tools: [{googleSearch: {}}]} : undefined,
  }));
  return response.text ?? "";
}
