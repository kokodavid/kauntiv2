// Public Trips photo worker. Claims pending photo jobs, sanitizes them, stores
// the copy in the private public-trip-media bucket and reports back with the
// generation it was given (the database refuses a stale report).
//
// One photo per request keeps each run inside the Edge Function CPU limit. When
// a photo was processed the function calls itself so a queue drains quickly;
// a scheduled call every minute is the safety net.
//
//   POST /            process the next photo
//   POST /?sweep=1    delete orphaned objects in public-trip-media
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { PhotoRejected, sanitizePhoto } from "./sanitize.ts";

const SOURCE_BUCKET = "journey-media";
const TARGET_BUCKET = "public-trip-media";
const SWEEP_MIN_AGE_MS = 60 * 60 * 1000;
const SWEEP_MAX_DELETES = 100;

interface Job {
  id: string;
  publication_id: string;
  revision: number;
  generation: number;
  source_path: string;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
}

function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

async function processNext(db: SupabaseClient): Promise<{ processed: boolean; outcome?: string }> {
  const { data, error } = await db.rpc("list_public_trip_photo_jobs", { p_limit: 1 });
  if (error) throw new Error(`claim failed: ${error.message}`);
  const job = (data as Job[])[0];
  if (!job) return { processed: false };

  const fail = async (reason: string) => {
    const { error: failError } = await db.rpc("fail_public_trip_photo", {
      p_photo_id: job.id,
      p_generation: job.generation,
      p_reason: reason,
    });
    if (failError) console.error("fail report failed", job.id, failError.message);
    return { processed: true, outcome: `failed: ${reason}` };
  };

  const download = await db.storage.from(SOURCE_BUCKET).download(job.source_path);
  if (download.error || !download.data) {
    // A missing source will never come back. Anything else may be transient,
    // so leave the photo claimed and let the lease expire for a retry.
    const status = (download.error as { status?: number; statusCode?: string | number } | null);
    const missing = status?.status === 404 || String(status?.statusCode) === "404";
    if (missing) return await fail("Source photo is no longer available");
    console.error("download failed", job.id, download.error?.message);
    return { processed: true, outcome: "retry: download failed" };
  }

  let photo;
  try {
    photo = await sanitizePhoto(new Uint8Array(await download.data.arrayBuffer()));
  } catch (e) {
    if (e instanceof PhotoRejected) return await fail(e.message);
    console.error("sanitize crashed", job.id, e);
    return { processed: true, outcome: "retry: sanitize error" };
  }

  const path = `${job.publication_id}/${job.revision}/${job.id}.jpg`;
  const upload = await db.storage.from(TARGET_BUCKET).upload(path, photo.bytes, {
    contentType: "image/jpeg",
    upsert: true,
    cacheControl: "3600",
  });
  if (upload.error) {
    console.error("upload failed", job.id, upload.error.message);
    return { processed: true, outcome: "retry: upload failed" };
  }

  const { data: accepted, error: completeError } = await db.rpc("complete_public_trip_photo", {
    p_photo_id: job.id,
    p_generation: job.generation,
    p_sanitized_path: path,
    p_width: photo.width,
    p_height: photo.height,
  });
  if (completeError || accepted !== true) {
    // Withdrawn or changed while processing: the copy must not linger.
    await db.storage.from(TARGET_BUCKET).remove([path]);
    if (completeError) console.error("complete failed", job.id, completeError.message);
    return { processed: true, outcome: completeError ? "retry: report failed" : "discarded: no longer wanted" };
  }
  return { processed: true, outcome: "ready" };
}

// Withdrawn or superseded revisions delete their database rows but not the
// stored copies. Remove objects nothing references, once they are old enough
// that an in-flight upload cannot be mistaken for an orphan.
async function sweep(db: SupabaseClient): Promise<{ deleted: number }> {
  const { data, error } = await db.rpc("public_trip_photo_paths_in_use");
  if (error) throw new Error(`in-use lookup failed: ${error.message}`);
  const inUse = new Set<string>(data as string[]);
  const bucket = db.storage.from(TARGET_BUCKET);
  const orphans: string[] = [];

  const publications = await bucket.list("", { limit: 1000 });
  for (const pub of publications.data ?? []) {
    const revisions = await bucket.list(pub.name, { limit: 1000 });
    for (const rev of revisions.data ?? []) {
      const files = await bucket.list(`${pub.name}/${rev.name}`, { limit: 1000 });
      for (const file of files.data ?? []) {
        const path = `${pub.name}/${rev.name}/${file.name}`;
        const created = Date.parse(file.created_at ?? "");
        if (!inUse.has(path) && Number.isFinite(created) && Date.now() - created > SWEEP_MIN_AGE_MS) {
          orphans.push(path);
        }
        if (orphans.length >= SWEEP_MAX_DELETES) break;
      }
      if (orphans.length >= SWEEP_MAX_DELETES) break;
    }
    if (orphans.length >= SWEEP_MAX_DELETES) break;
  }
  if (orphans.length > 0) {
    const removed = await bucket.remove(orphans);
    if (removed.error) throw new Error(`sweep failed: ${removed.error.message}`);
  }
  return { deleted: orphans.length };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const workerSecret = Deno.env.get("PUBLIC_TRIP_WORKER_SECRET");
  const url = Deno.env.get("SUPABASE_URL");
  if (!serviceKey || !url || !workerSecret || workerSecret.length < 32) {
    return json({ error: "not configured" }, 500);
  }
  // Deployed with --no-verify-jwt. Callers present a dedicated worker secret,
  // not the service role key, so the scheduler never holds database-wide
  // access and the check does not depend on which key format the project uses.
  const presented = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!safeEqual(presented, workerSecret)) return json({ error: "unauthorized" }, 401);

  const db = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  try {
    if (new URL(req.url).searchParams.get("sweep") === "1") return json(await sweep(db));
    const result = await processNext(db);
    if (result.processed) {
      // Keep draining the queue; each call gets a fresh CPU budget.
      const self = `${url}/functions/v1/public-trip-photo-worker`;
      const next = fetch(self, { method: "POST", headers: { authorization: `Bearer ${workerSecret}` } })
        .catch((e) => console.error("chain failed", e));
      // deno-lint-ignore no-explicit-any
      (globalThis as any).EdgeRuntime?.waitUntil(next);
    }
    return json(result);
  } catch (e) {
    console.error(e);
    return json({ error: "worker error" }, 500);
  }
});
