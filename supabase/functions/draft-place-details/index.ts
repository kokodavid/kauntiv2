// Drafts the "Add a place" form fields from a place name using Claude with web
// search and fetch. Dashboard admins call it with their own session; nothing
// is written to public.places, the admin reviews and saves through the normal
// create_place_dashboard_entry flow.
//
// Deploy (JWT verification stays on):
//   supabase functions deploy draft-place-details
// Secrets (per environment): ANTHROPIC_API_KEY. SUPABASE_URL,
// SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY come from the platform.
// The model is read from public.place_ai_settings (switch it in the dashboard
// Settings page).

import { createClient } from 'npm:@supabase/supabase-js@2'
import { researchPlace } from './anthropic.ts'
import { cleanDraft } from './validate.ts'

const cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'content-type': 'application/json', 'cache-control': 'no-store' },
  })

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response(null, { headers: cors })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  const url = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
  const auth = request.headers.get('authorization')
  if (!url || !anonKey || !serviceKey || !apiKey) return json({ error: 'AI drafting is not configured' }, 500)
  if (!auth) return json({ error: 'Sign in required' }, 401)

  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: auth } } })
  const { data: userData } = await userClient.auth.getUser()
  const userId = userData.user?.id
  if (!userId) return json({ error: 'Sign in required' }, 401)

  const { data: role } = await userClient.rpc('current_admin_role')
  if (!['owner', 'admin', 'editor'].includes(role as string)) {
    return json({ error: 'Dashboard access required' }, 403)
  }

  let body: { query?: unknown; county_id?: unknown }
  try {
    body = await request.json()
  } catch {
    return json({ error: 'Invalid JSON' }, 400)
  }
  const query = typeof body.query === 'string' ? body.query.trim() : ''
  if (query.length < 3 || query.length > 120) return json({ error: 'Enter a place name (3-120 characters)' }, 400)

  const service = createClient(url, serviceKey)
  const { data: settings } = await service
    .from('place_ai_settings')
    .select('model, daily_limit_per_admin')
    .eq('id', true)
    .single()
  if (!settings) return json({ error: 'AI settings are missing' }, 500)

  const since = new Date()
  since.setUTCHours(0, 0, 0, 0)
  const { count } = await service
    .from('place_ai_runs')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('created_at', since.toISOString())
  if ((count ?? 0) >= settings.daily_limit_per_admin) {
    return json({ error: 'Daily AI draft limit reached' }, 429)
  }

  const log = (status: string, usage?: { input: number; output: number; searches: number }) =>
    service.from('place_ai_runs').insert({
      user_id: userId,
      query,
      model: settings.model,
      status,
      input_tokens: usage?.input ?? null,
      output_tokens: usage?.output ?? null,
      web_searches: usage?.searches ?? null,
    })

  const { data: similar } = await service.rpc('place_ai_similar_places', { p_name: query })
  if (similar && similar.length > 0) {
    await log('duplicate')
    return json({ status: 'duplicate', existing: similar })
  }

  let countyHint: string | null = null
  if (typeof body.county_id === 'number') {
    const { data } = await service.from('counties').select('name').eq('id', body.county_id).maybeSingle()
    countyHint = data?.name ?? null
  }

  try {
    const { draft: raw, usage } = await researchPlace(apiKey, settings.model, query, countyHint)
    if (!raw) {
      await log('error', usage)
      return json({ error: 'The AI did not return a draft. Try again.' }, 502)
    }
    if (raw.found !== true) {
      await log('not_found', usage)
      return json({ status: 'not_found', notes: Array.isArray(raw.notes) ? raw.notes : [] })
    }

    const draft = cleanDraft(raw)
    let county_id: number | null = null
    if (draft.county_name) {
      const { data } = await service.from('counties').select('id').ilike('name', draft.county_name).maybeSingle()
      county_id = data?.id ?? null
    }
    if (county_id === null) draft.notes.push('County could not be matched; please choose it.')

    if (draft.lat !== null && draft.lng !== null) {
      const { data } = await service.rpc('place_ai_county_for_point', { p_lat: draft.lat, p_lng: draft.lng })
      const hit = Array.isArray(data) ? data[0] : null
      if (!hit) {
        draft.notes.push('Coordinates do not fall inside any county and were dropped.')
        draft.lat = draft.lng = null
        draft.coordinate_confidence = 'none'
      } else if (county_id !== null && hit.id !== county_id) {
        draft.notes.push(`Coordinates fall in ${hit.name}, not the chosen county. Check the pin before saving.`)
        draft.coordinate_confidence = 'landmark'
      }
    }

    await log('ok', usage)
    return json({ status: 'ok', model: settings.model, county_id, draft })
  } catch (error) {
    console.error('draft-place-details failed', error)
    await log('error')
    return json({ error: 'AI drafting failed. Try again.' }, 502)
  }
})
