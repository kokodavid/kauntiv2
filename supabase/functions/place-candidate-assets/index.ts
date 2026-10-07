// Dashboard-only private asset operations. Unlike ingest, this function uses
// the caller's Supabase session and verifies the dashboard admin role before
// creating a signed preview or copying approved assets to the public bucket.

import { createClient } from 'npm:@supabase/supabase-js@2'

const STAGING_BUCKET = 'place-candidate-staging'
const PUBLIC_BUCKET = 'place-images'
const corsHeaders = {
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-origin': '*',
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, 'content-type': 'application/json', 'cache-control': 'no-store' },
})

const isString = (value: unknown): value is string => typeof value === 'string' && value.length > 0

async function requireEditor(request: Request) {
  const url = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('authorization')
  if (!url || !anonKey || !serviceKey || !authorization) throw new Error('Not configured')
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } })
  const { data: userData, error: userError } = await userClient.auth.getUser()
  if (userError || !userData.user) throw new Error('Unauthorized')
  const { data: role, error: roleError } = await userClient.rpc('current_admin_role')
  if (roleError || !['owner', 'admin', 'editor'].includes(role as string)) throw new Error('Forbidden')
  return { url, userClient, serviceClient: createClient(url, serviceKey, { auth: { persistSession: false } }) }
}

async function preview(serviceClient: ReturnType<typeof createClient>, candidateId: string, imageId: string) {
  const { data: candidate } = await serviceClient.from('place_candidates').select('origin').eq('id', candidateId).maybeSingle()
  if (!candidate || candidate.origin !== 'scraper') return json({ error: 'Scraped candidate not found' }, 404)
  const { data: image, error } = await serviceClient.from('place_candidate_images')
    .select('id, staging_path, review_status').eq('id', imageId).eq('candidate_id', candidateId).maybeSingle()
  if (error || !image?.staging_path) return json({ error: 'Staged image not found' }, 404)
  const { data, error: signedError } = await serviceClient.storage.from(STAGING_BUCKET).createSignedUrl(image.staging_path, 900)
  if (signedError || !data?.signedUrl) return json({ error: 'Could not create preview' }, 500)
  return json({ image_id: image.id, review_status: image.review_status, signed_url: data.signedUrl })
}

async function publish(url: string, userClient: ReturnType<typeof createClient>, serviceClient: ReturnType<typeof createClient>, candidateId: string, note: string | null) {
  const { data: candidate } = await serviceClient.from('place_candidates').select('id, origin, status').eq('id', candidateId).maybeSingle()
  if (!candidate || candidate.origin !== 'scraper' || candidate.status !== 'pending_review') return json({ error: 'Pending scraped candidate not found' }, 404)
  const { data: images, error } = await serviceClient.from('place_candidate_images')
    .select('id, staging_path, staged_content_type, sort_order')
    .eq('candidate_id', candidateId)
    .eq('review_status', 'approved')
    .not('staging_path', 'is', null)
  if (error || !images?.length) return json({ error: 'At least one approved staged image is required' }, 400)

  const copiedPaths: string[] = []
  const publicImages: Array<{ candidate_image_id: string; image_url: string; thumbnail_url: string }> = []
  try {
    for (const image of images) {
      const extension = image.staging_path!.split('.').pop() ?? 'jpg'
      const destination = `${candidateId}/${image.id}.${extension}`
      const { data: asset, error: downloadError } = await serviceClient.storage.from(STAGING_BUCKET).download(image.staging_path!)
      if (downloadError || !asset) throw new Error(downloadError?.message ?? 'Could not download approved image')
      const { error: uploadError } = await serviceClient.storage.from(PUBLIC_BUCKET).upload(destination, asset, {
        contentType: image.staged_content_type ?? undefined,
        upsert: true,
      })
      if (uploadError) throw new Error(uploadError.message)
      copiedPaths.push(destination)
      const publicUrl = `${url}/storage/v1/object/public/${PUBLIC_BUCKET}/${destination}`
      publicImages.push({ candidate_image_id: image.id, image_url: publicUrl, thumbnail_url: publicUrl })
    }
  } catch (copyError) {
    await serviceClient.storage.from(PUBLIC_BUCKET).remove(copiedPaths)
    const message = copyError instanceof Error ? copyError.message : 'Could not copy approved image'
    return json({ error: `Could not copy approved image: ${message}` }, 500)
  }
  const { data: place, error: publishError } = await userClient.rpc('publish_scraped_place_candidate_dashboard', {
    p_candidate_id: candidateId, p_public_images: publicImages, p_review_note: note,
  })
  if (publishError) {
    await serviceClient.storage.from(PUBLIC_BUCKET).remove(copiedPaths)
    return json({ error: publishError.message }, 400)
  }
  return json(place)
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)
  let body: Record<string, unknown>
  try { body = await request.json() } catch { return json({ error: 'Invalid JSON' }, 400) }
  try {
    const { url, userClient, serviceClient } = await requireEditor(request)
    if (body.action === 'preview' && isString(body.candidate_id) && isString(body.image_id)) {
      return preview(serviceClient, body.candidate_id, body.image_id)
    }
    if (body.action === 'publish' && isString(body.candidate_id)) {
      return publish(url, userClient, serviceClient, body.candidate_id, typeof body.review_note === 'string' ? body.review_note.trim() || null : null)
    }
    return json({ error: 'Unknown action' }, 400)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Request failed'
    return json({ error: message }, message === 'Unauthorized' ? 401 : message === 'Forbidden' ? 403 : 500)
  }
})
