import {applicationDefault, cert, getApps, initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {randomUUID} from "node:crypto";
import {basename} from "node:path";
import {env, PATHS, PIPELINE_VERSION} from "./config.js";
import {getIngredient, per100g} from "./ingredients.js";
import {type IndexEntry, IngredientDoc, type RecipeDoc} from "./schema.js";
import {readJson, readStage, stageIds, writeJson} from "./store.js";

function app() {
  if (!getApps().length) {
    const credential = process.env.GOOGLE_APPLICATION_CREDENTIALS ?
      cert(process.env.GOOGLE_APPLICATION_CREDENTIALS) : applicationDefault();
    initializeApp({credential, projectId: env.firebaseProject, storageBucket: env.storageBucket});
  }
  return {db: getFirestore(), bucket: getStorage().bucket()};
}

export interface UploadOptions {
  batch: string;
  /** Write to Firebase; otherwise only print the plan. */
  apply: boolean;
  /** Also publish recipes flagged needsReview (as drafts). */
  includeReview: boolean;
  /** Publish even when a referenced master row is still pending. */
  allowPending: boolean;
}

/** Push the batch's final docs, their ingredients and photos; bump meta/catalogue. */
export async function upload(opts: UploadOptions): Promise<void> {
  const ids = stageIds(opts.batch, "final");
  const recipes = ids.map((id) => readStage<RecipeDoc>(opts.batch, "final", id))
    .filter((r) => !r.reviewNotes.some((n) => n.startsWith("duplicate of")))
    .filter((r) => opts.includeReview || !r.needsReview);
  const slugs = [...new Set(recipes.flatMap((r) => r.ingredients.map((i) => i.ingredientId)))];
  const pending = slugs.filter((s) => getIngredient(s)?.status !== "approved");
  if (pending.length && !opts.allowPending) {
    throw new Error(`${pending.length} ingredients not verified yet (run fill-ciqual / review-ingredients, or --allow-pending): ${pending.join(", ")}`);
  }
  console.log(`[upload] ${recipes.length} recipes (${recipes.filter((r) => r.status === "published").length} published), ${slugs.length} ingredients`);
  for (const r of recipes) console.log(`  ${r.id} ${r.status.padEnd(9)} ${r.title.fr}`);
  if (!opts.apply) {
    console.log("[upload] dry run; pass --apply to write");
    return;
  }

  const {db, bucket} = app();
  const seen = readJson<Record<string, string>>(PATHS.seen, {});
  const now = FieldValue.serverTimestamp();

  for (const recipe of recipes) {
    // Photos: Firebase download-token URLs (the org policy forbids allUsers IAM, so no makePublic).
    const photo = {...recipe.photo};
    for (const kind of ["hero", "thumb"] as const) {
      const local = recipe.photo[kind];
      const dest = `recipes/${recipe.id}/${basename(local)}`;
      const token = randomUUID();
      await bucket.upload(local, {
        destination: dest,
        metadata: {cacheControl: "public, max-age=31536000", contentType: "image/jpeg", metadata: {firebaseStorageDownloadTokens: token}},
      });
      photo[kind] = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(dest)}?alt=media&token=${token}`;
    }
    await db.doc(`recipes/${recipe.id}`).set({...recipe, photo, createdAt: now, updatedAt: now});
    seen[String(recipe.sourceId)] = recipe.id;
    console.log(`[upload] wrote recipes/${recipe.id}`);
  }

  const batch = db.batch();
  for (const slug of slugs) {
    const row = getIngredient(slug)!;
    const {status: _s, aliases: _a, ...rest} = row;
    batch.set(db.doc(`ingredients/${slug}`), IngredientDoc.parse({...rest, per100g: per100g(row)}), {merge: true});
  }
  batch.set(db.doc("meta/catalogue"), {version: FieldValue.increment(1), pipelineVersion: PIPELINE_VERSION, updatedAt: now}, {merge: true});
  await batch.commit();
  writeJson(PATHS.seen, seen);
  console.log(`[upload] wrote ${slugs.length} ingredients and meta/catalogue`);
}

/** Refresh work/published-index.json from Firestore so dedupe sees everything already live. */
export async function pullIndex(): Promise<number> {
  const {db} = app();
  const snapshot = await db.collection("recipes").select("sourceId", "title", "ingredients", "protein").get();
  const index: IndexEntry[] = snapshot.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      sourceId: data.sourceId,
      titleEn: data.title?.en ?? "",
      ingredientIds: [...new Set<string>((data.ingredients ?? []).map((i: any) => String(i.ingredientId)))],
      protein: data.protein,
    };
  });
  writeJson(PATHS.publishedIndex, index);
  return index.length;
}
