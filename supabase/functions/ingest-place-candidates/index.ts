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
    default:
      return json({ error: 'Unknown action' }, 400)
  }
})
