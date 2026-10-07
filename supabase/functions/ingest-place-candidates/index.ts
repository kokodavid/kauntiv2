// The only way a scraper reaches the database. It holds no scraping logic:
// it authenticates the caller with a dedicated ingest key and forwards three
// actions to service-role-only RPCs that write to place_candidates and the
// run log, never to public.places.
//
// Deploy without JWT verification (callers present the ingest key instead):
//   supabase functions deploy ingest-place-candidates --no-verify-jwt
// Secrets: SCRAPER_INGEST_KEY (set per environment). SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from 'npm:@supabase/supabase-js@2'

const MAX_BODY_BYTES = 1_000_000
const MAX_ITEMS = 100
const MAX_STAGE_IDS = 100
const MAX_IMAGE_BYTES = 8_000_000
const STAGING_BUCKET = 'place-candidate-staging'

type StagingImage = {
  id: string
  candidate_id: string
  scrape_image_key: string
  remote_url: string
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
  })

async function sameSecret(given: string, expected: string): Promise<boolean> {
  const encoder = new TextEncoder()
  const [a, b] = await Promise.all([
    crypto.subtle.digest('SHA-256', encoder.encode(given)),
    crypto.subtle.digest('SHA-256', encoder.encode(expected)),
  ])
  const x = new Uint8Array(a)
  const y = new Uint8Array(b)
  let diff = 0
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i]
  return diff === 0
}

// Postgres error codes raised by the RPCs, mapped to HTTP statuses.
function failure(error: { code?: string; message: string }) {
  switch (error.code) {
    case 'P0002':
      return json({ error: error.message }, 404)
    case '55000':
    case '55P03':
      return json({ error: error.message }, 409)
    case '22023':
      return json({ error: error.message }, 400)
    default:
      console.error('ingest-place-candidates RPC failed', error)
      return json({ error: 'Ingest failed' }, 500)
  }
}

const isString = (value: unknown): value is string => typeof value === 'string' && value.length > 0

function trustedCommonsUrl(value: string): URL | null {
  try {
    const url = new URL(value)
    if (url.protocol !== 'https:' || !['upload.wikimedia.org', 'commons.wikimedia.org'].includes(url.hostname)) return null
    return url
  } catch {
    return null
  }
}

async function stageImage(client: ReturnType<typeof createClient>, image: StagingImage) {
  const remote = trustedCommonsUrl(image.remote_url)
  if (!remote) throw new Error('Image URL is not a trusted Wikimedia Commons URL')
  const response = await fetch(remote, { redirect: 'error' })
  const contentType = response.headers.get('content-type')?.split(';')[0].toLowerCase() ?? ''
  const contentLength = Number(response.headers.get('content-length') ?? '0')
  if (!response.ok) throw new Error(`Image download failed with ${response.status}`)
  if (!contentType.startsWith('image/') || contentLength > MAX_IMAGE_BYTES) throw new Error('Image type or size is not allowed')
  const bytes = new Uint8Array(await response.arrayBuffer())
  if (bytes.byteLength > MAX_IMAGE_BYTES) throw new Error('Image exceeds the 8 MB staging limit')
  const extension = contentType === 'image/png' ? 'png' : contentType === 'image/webp' ? 'webp' : 'jpg'
  const path = `${image.candidate_id}/${image.id}.${extension}`
  const { error: uploadError } = await client.storage.from(STAGING_BUCKET).upload(path, bytes, {
    contentType,
    upsert: true,
  })
  if (uploadError) throw new Error(`Staging upload failed: ${uploadError.message}`)
  const { error: updateError } = await client.from('place_candidate_images').update({
    staging_path: path,
    staged_at: new Date().toISOString(),
    staged_content_type: contentType,
    staged_bytes: bytes.byteLength,
    stage_failure_reason: null,
    review_status: 'pending',
  }).eq('id', image.id)
  if (updateError) throw new Error(`Image staging update failed: ${updateError.message}`)
}

async function stageCandidateImages(client: ReturnType<typeof createClient>, candidateIds: string[]) {
  const uniqueIds = [...new Set(candidateIds)]
  const { data: candidates, error: candidateError } = await client
    .from('place_candidates')
    .select('id')
    .in('id', uniqueIds)
    .eq('origin', 'scraper')
    .eq('status', 'pending_review')
  if (candidateError) return failure(candidateError)
  const pendingCandidateIds = (candidates ?? []).map((candidate) => candidate.id)
  if (!pendingCandidateIds.length) return json({ results: [] })
  const { data, error } = await client
    .from('place_candidate_images')
    .select('id, candidate_id, scrape_image_key, remote_url')
    .in('candidate_id', pendingCandidateIds)
    .not('scrape_image_key', 'is', null)
    .not('remote_url', 'is', null)
    .is('staging_path', null)
    .in('review_status', ['pending', 'failed'])
  if (error) return failure(error)
  const results = []
  for (const image of data ?? []) {
    try {
      await stageImage(client, image as StagingImage)
      results.push({ image_id: image.id, outcome: 'staged' })
    } catch (error) {
      const detail = error instanceof Error ? error.message : 'Image staging failed'
      await client.from('place_candidate_images').update({
        review_status: 'failed', stage_failure_reason: detail.slice(0, 300),
      }).eq('id', image.id)
      results.push({ image_id: image.id, outcome: 'failed', detail })
    }
  }
  return json({ results })
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  const expectedKey = Deno.env.get('SCRAPER_INGEST_KEY')
  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!expectedKey || !url || !serviceKey) return json({ error: 'Ingest is not configured' }, 500)

  const givenKey = request.headers.get('x-ingest-key') ?? ''
  if (!(await sameSecret(givenKey, expectedKey))) return json({ error: 'Unauthorized' }, 401)

  const declared = Number(request.headers.get('content-length') ?? '0')
  if (declared > MAX_BODY_BYTES) return json({ error: 'Payload too large' }, 413)
  const text = await request.text()
  if (text.length > MAX_BODY_BYTES) return json({ error: 'Payload too large' }, 413)

  let body: Record<string, unknown>
  try {
    body = JSON.parse(text)
  } catch {
    return json({ error: 'Invalid JSON' }, 400)
  }

  const client = createClient(url, serviceKey, { auth: { persistSession: false } })

  switch (body.action) {
    case 'start': {
      if (!isString(body.source)) return json({ error: 'source is required' }, 400)
      const triggeredBy = body.triggered_by === 'manual' ? 'manual' : 'schedule'
      const { data, error } = await client.rpc('start_scrape_run', {
        p_source_slug: body.source,
        p_triggered_by: triggeredBy,
        p_dry_run: body.dry_run === true,
      })
      return error ? failure(error) : json(data)
    }
    case 'items': {
      if (!isString(body.run_id)) return json({ error: 'run_id is required' }, 400)
      if (!Array.isArray(body.items) || body.items.length > MAX_ITEMS) {
        return json({ error: `items must be an array of at most ${MAX_ITEMS}` }, 400)
      }
      const { data, error } = await client.rpc('ingest_scrape_items', {
        p_run_id: body.run_id,
        p_items: body.items,
      })
      return error ? failure(error) : json({ results: data })
    }
    case 'finish': {
      if (!isString(body.run_id) || !isString(body.status)) {
        return json({ error: 'run_id and status are required' }, 400)
      }
      const { error } = await client.rpc('finish_scrape_run', {
        p_run_id: body.run_id,
        p_status: body.status,
        p_checkpoint: body.checkpoint ?? null,
        p_error_summary: typeof body.error_summary === 'string' ? body.error_summary : null,
      })
      return error ? failure(error) : json({ ok: true })
    }
    case 'stage_images': {
      if (!Array.isArray(body.candidate_ids) || body.candidate_ids.length > MAX_STAGE_IDS
        || !body.candidate_ids.every(isString)) {
        return json({ error: `candidate_ids must be an array of at most ${MAX_STAGE_IDS} ids` }, 400)
      }
      return stageCandidateImages(client, body.candidate_ids)
    }
    default:
      return json({ error: 'Unknown action' }, 400)
  }
})
