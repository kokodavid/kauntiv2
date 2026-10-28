// Receives RevenueCat webhooks and turns store purchases into Pro periods.
// All rules live in the apply_revenuecat_event RPC; this only checks the
// caller and hands the event over.
//
// Deploy without JWT verification (RevenueCat is not a Supabase user):
//   supabase functions deploy revenuecat-webhook --no-verify-jwt
// Secret: REVENUECAT_WEBHOOK_AUTH, the exact value entered in RevenueCat as
// the webhook "Authorization header value". SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY are provided by the platform.
//
// Answers 200 for anything handled or deliberately ignored, and 500 only when
// saving failed, so RevenueCat retries the event.

import { createClient } from 'npm:@supabase/supabase-js@2'

const MAX_BODY_BYTES = 100_000

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json', 'cache-control': 'no-store' },
})

// Compare without leaking where the first difference is.
function sameSecret(given: string, expected: string): boolean {
  const a = new TextEncoder().encode(given)
  const b = new TextEncoder().encode(expected)
  let diff = a.length ^ b.length
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    diff |= (a[i] ?? 0) ^ (b[i] ?? 0)
  }
  return diff === 0
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  const expected = Deno.env.get('REVENUECAT_WEBHOOK_AUTH')
  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!expected || !url || !serviceKey) return json({ error: 'Not configured' }, 500)

  const given = request.headers.get('authorization') ?? ''
  if (!sameSecret(given, expected)) return json({ error: 'Unauthorized' }, 401)

  const raw = await request.text()
  if (raw.length > MAX_BODY_BYTES) return json({ error: 'Too large' }, 413)

  let event: unknown
  try {
    event = (JSON.parse(raw) as { event?: unknown }).event
  } catch {
    return json({ error: 'Invalid JSON' }, 400)
  }
  if (typeof event !== 'object' || event === null) {
    return json({ error: 'Missing event' }, 400)
  }

  const service = createClient(url, serviceKey, { auth: { persistSession: false } })
  const { data, error } = await service.rpc('apply_revenuecat_event', { p_event: event })
  if (error) {
    console.error('apply_revenuecat_event failed', error.message)
    return json({ error: 'Could not save' }, 500)
  }
  return json({ result: data })
})
