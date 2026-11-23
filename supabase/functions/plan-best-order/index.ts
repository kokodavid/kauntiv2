// Best order for one plan day (Pro). The caller must be a member who can
// edit the plan, on a plan whose owner has Pro: the database function
// `trip_plan_day_order_input` checks that, applies the hourly limit and
// returns the day's stops. This function asks Mapbox for driving times
// between them (Matrix API, up to 25 points), works out a short order and
// returns the stop ids. The app then saves the order with
// `set_trip_plan_day_order`.
//
// Deploy with JWT verification on (the default):
//   supabase functions deploy plan-best-order
// Secret: MAPBOX_SECRET_TOKEN (or MAPBOX_ACCESS_TOKEN), a token that may
// call the Matrix API. SUPABASE_URL and SUPABASE_ANON_KEY come from the
// platform.

import { createClient } from 'npm:@supabase/supabase-js@2'
import { bestOrder, Matrix } from './order.ts'

const corsHeaders = {
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-origin': '*',
}
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json', 'cache-control': 'no-store' },
  })

const MAX_STOPS = 24 // the Matrix API takes 25 points, and the start is one

// Database error codes (the message of the raised exception) to answers.
const refusals: Record<string, number> = {
  trip_plans_unavailable: 403,
  not_signed_in: 401,
  trip_plan_not_found: 404,
  trip_plan_view_only: 403,
  trip_plan_limit_best_order: 403,
  trip_plan_rate_limited: 429,
  trip_plan_bad_input: 400,
}

type Stop = { id: string; lat: number; lng: number }

const inRange = (value: unknown, min: number, max: number): value is number =>
  typeof value === 'number' && Number.isFinite(value) && value >= min && value <= max

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405)

  const url = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const token = Deno.env.get('MAPBOX_SECRET_TOKEN') ?? Deno.env.get('MAPBOX_ACCESS_TOKEN')
  const authorization = request.headers.get('authorization')
  if (!url || !anonKey || !token) return json({ error: 'not_configured' }, 500)
  if (!authorization) return json({ error: 'not_signed_in' }, 401)

  let body: { day_id?: unknown; start?: { lat?: unknown; lng?: unknown } }
  try {
    body = await request.json()
  } catch {
    return json({ error: 'trip_plan_bad_input' }, 400)
  }
  const dayId = typeof body.day_id === 'string' ? body.day_id : ''
  const start = body.start
  if (!/^[0-9a-f-]{36}$/i.test(dayId) || !inRange(start?.lat, -90, 90) || !inRange(start?.lng, -180, 180)) {
    return json({ error: 'trip_plan_bad_input' }, 400)
  }

  // As the member: the database sees their id and applies their role.
  const supabase = createClient(url, anonKey, { global: { headers: { authorization } } })
  const { data, error } = await supabase.rpc('trip_plan_day_order_input', { p_day: dayId })
  if (error) {
    const status = refusals[error.message]
    return json({ error: status ? error.message : 'trip_plan_unknown' }, status ?? 500)
  }
  const stops = ((data as { stops?: Stop[] })?.stops ?? []).filter(
    (s) => inRange(s.lat, -90, 90) && inRange(s.lng, -180, 180),
  )
  const all = (data as { stops?: Stop[] })?.stops ?? []
  if (stops.length !== all.length || stops.length < 2 || stops.length > MAX_STOPS) {
    return json({ error: 'trip_plan_bad_input' }, 400)
  }

  const points = [{ lat: start.lat, lng: start.lng }, ...stops]
  const coordinates = points.map((p) => `${p.lng.toFixed(6)},${p.lat.toFixed(6)}`).join(';')
  let matrix: Matrix
  try {
    const response = await fetch(
      `https://api.mapbox.com/directions-matrix/v1/mapbox/driving/${coordinates}` +
        `?annotations=duration&access_token=${encodeURIComponent(token)}`,
      { signal: AbortSignal.timeout(8000) },
    )
    if (!response.ok) return json({ error: 'trip_plan_routing_failed' }, 502)
    const parsed = await response.json()
    if (parsed.code !== 'Ok' || !Array.isArray(parsed.durations)) {
      return json({ error: 'trip_plan_routing_failed' }, 502)
    }
    matrix = parsed.durations
  } catch {
    return json({ error: 'trip_plan_routing_failed' }, 502)
  }

  const order = bestOrder(matrix) // indexes into points, 1-based over stops
  return json({ stop_ids: order.map((index) => stops[index - 1].id) })
})
