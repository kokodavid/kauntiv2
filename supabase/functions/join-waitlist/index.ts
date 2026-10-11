// Public endpoint behind the kaunti47.com landing-page form. It validates the
// request, then calls the service-only join_waitlist RPC. No account is needed.
//
// Deploy without JWT verification (visitors are anonymous):
//   supabase functions deploy join-waitlist --no-verify-jwt
// Optional secret: ALLOWED_ORIGINS, a comma-separated list such as
//   https://kaunti47.com,https://www.kaunti47.com
// (leave unset to allow any origin while testing). SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY are provided by the platform.

import { createClient } from 'npm:@supabase/supabase-js@2'

const MAX_BODY_BYTES = 4_000

const allowed = (Deno.env.get('ALLOWED_ORIGINS') ?? '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean)

function corsHeaders(origin: string | null): Record<string, string> {
  const ok = allowed.length === 0 || (origin !== null && allowed.includes(origin))
  return {
    'access-control-allow-origin': ok ? (origin ?? '*') : allowed[0],
    'access-control-allow-headers': 'content-type, authorization, apikey, x-client-info',
    'access-control-allow-methods': 'POST, OPTIONS',
    vary: 'origin',
  }
}

const json = (body: unknown, status: number, origin: string | null) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(origin), 'content-type': 'application/json', 'cache-control': 'no-store' },
  })

Deno.serve(async (request) => {
  const origin = request.headers.get('origin')
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders(origin) })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405, origin)
  if (allowed.length > 0 && (origin === null || !allowed.includes(origin))) {
    return json({ error: 'Not allowed' }, 403, origin)
  }

  const url = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!url || !serviceKey) return json({ error: 'Signups are not configured' }, 500, origin)

  const raw = await request.text()
  if (raw.length > MAX_BODY_BYTES) return json({ error: 'Request too large' }, 413, origin)

  let body: Record<string, unknown>
  try {
    body = JSON.parse(raw)
  } catch {
    return json({ error: 'Invalid JSON' }, 400, origin)
  }

  // Honeypot: real visitors never fill the hidden "website" field. Pretend it
  // worked so bots do not learn to skip it.
  if (typeof body.website === 'string' && body.website.trim() !== '') {
    return json({ ok: true, answered: false }, 200, origin)
  }

  const str = (value: unknown, max: number) => (typeof value === 'string' ? value.trim().slice(0, max) : '')

  // Step one sends only the email; step two repeats it with every answer.
  const hasAnswers = ['base_county', 'platform', 'counties_visited', 'travel_frequency', 'upcoming_trip'].some(
    (key) => body[key] !== undefined && body[key] !== null && body[key] !== '',
  ) || body.accepts_rules !== undefined

  const supabase = createClient(url, serviceKey)
  const { data, error } = await supabase.rpc('join_waitlist', {
    p_email: str(body.email, 254),
    p_source: str(body.source, 40),
    p_base_county: hasAnswers ? (str(body.base_county, 40) || null) : null,
    p_platform: hasAnswers ? (str(body.platform, 10) || null) : null,
    p_counties_visited: hasAnswers ? (str(body.counties_visited, 10) || null) : null,
    p_travel_frequency: hasAnswers ? (str(body.travel_frequency, 20) || null) : null,
    p_upcoming_trip: hasAnswers ? (str(body.upcoming_trip, 20) || null) : null,
    p_accepts_rules: hasAnswers ? body.accepts_rules === true : null,
  })

  if (error) {
    if (error.code === '22023') return json({ error: error.message }, 400, origin)
    if (error.code === '54000') return json({ error: error.message }, 429, origin)
    console.error('join-waitlist failed', error)
    return json({ error: 'Something went wrong. Please try again.' }, 500, origin)
  }
  return json(data, 200, origin)
})
