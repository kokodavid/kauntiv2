// Approves or rejects a user-submitted place photo from the dashboard.
//
// Approve: copies the photo and its thumbnail from the private
// `place-photo-submissions` bucket into the public `place-images` bucket, then
// records it through `review_place_photo_dashboard` (which adds the
// `place_images` row with the contributor's username as credit). The private
// copies are deleted afterwards, approved or rejected, so an unpublished photo
// does not outlive its review.
//
// The reviewer's own JWT is used for the role check and the database write,
// so the same owner/admin/editor rule as the rest of the dashboard applies.

import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-origin': '*',
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, 'content-type': 'application/json', 'cache-control': 'no-store' },
})

const PRIVATE_BUCKET = 'place-photo-submissions'
const PUBLIC_BUCKET = 'place-images'

type Submission = {
  id: string
  user_id: string
  place_id: string
  storage_path: string
  thumb_path: string
  status: string
}

async function requireEditor(request: Request) {
  const url = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('authorization')
  if (!url || !anonKey || !serviceKey || !authorization) throw new Error('Not configured')
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } })
  const { data: user, error: userError } = await userClient.auth.getUser()
  if (userError || !user.user) throw new Error('Unauthorized')
  const { data: role, error: roleError } = await userClient.rpc('current_admin_role')
  if (roleError || !['owner', 'admin', 'editor'].includes(role as string)) throw new Error('Forbidden')
  return { userClient, serviceClient: createClient(url, serviceKey, { auth: { persistSession: false } }) }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  try {
    const body = await request.json() as { submission_id?: unknown; approve?: unknown; reason?: unknown }
    if (typeof body.submission_id !== 'string' || !body.submission_id) {
      return json({ error: 'submission_id is required' }, 400)
    }
    if (typeof body.approve !== 'boolean') return json({ error: 'approve must be true or false' }, 400)
    const reason = typeof body.reason === 'string' ? body.reason.trim() : ''
    if (!body.approve && !reason) return json({ error: 'A reason is required to reject a photo' }, 400)

    const { userClient, serviceClient } = await requireEditor(request)

    const { data: found, error: findError } = await serviceClient
      .from('place_photo_submissions')
      .select('id, user_id, place_id, storage_path, thumb_path, status')
      .eq('id', body.submission_id)
      .maybeSingle()
    if (findError) return json({ error: findError.message }, 400)
    const submission = found as Submission | null
    if (!submission) return json({ error: 'Submission not found' }, 404)
    if (submission.status !== 'pending') return json({ error: 'This photo was already reviewed' }, 409)

    let imageUrl: string | null = null
    let thumbUrl: string | null = null
    const published: string[] = []

    if (body.approve) {
      const base = `user-photos/${submission.place_id}/${submission.id}`
      const copies = [
        { from: submission.storage_path, to: `${base}.jpg` },
        { from: submission.thumb_path, to: `${base}_thumb.jpg` },
      ]
      for (const copy of copies) {
        const { data: file, error: downloadError } = await serviceClient.storage
          .from(PRIVATE_BUCKET).download(copy.from)
        if (downloadError || !file) throw new Error('Could not read the submitted photo')
        const { error: uploadError } = await serviceClient.storage
          .from(PUBLIC_BUCKET)
          .upload(copy.to, file, { contentType: 'image/jpeg', upsert: true, cacheControl: '31536000' })
        if (uploadError) throw new Error(`Could not publish the photo: ${uploadError.message}`)
        published.push(copy.to)
      }
      imageUrl = serviceClient.storage.from(PUBLIC_BUCKET).getPublicUrl(published[0]).data.publicUrl
      thumbUrl = serviceClient.storage.from(PUBLIC_BUCKET).getPublicUrl(published[1]).data.publicUrl
    }

    const { data: reviewed, error: reviewError } = await userClient.rpc('review_place_photo_dashboard', {
      p_id: submission.id,
      p_approve: body.approve,
      p_reason: reason || null,
      p_image_url: imageUrl,
      p_thumbnail_url: thumbUrl,
    })
    if (reviewError) {
      // Do not leave published copies behind for a photo that was not recorded.
      if (published.length) await serviceClient.storage.from(PUBLIC_BUCKET).remove(published)
      return json({ error: reviewError.message }, reviewError.code === '42501' ? 403 : 400)
    }

    // Reviewed either way: the private copies are no longer needed.
    await serviceClient.storage.from(PRIVATE_BUCKET).remove([submission.storage_path, submission.thumb_path])

    return json({ status: body.approve ? 'approved' : 'rejected', submission: reviewed })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Could not review the photo'
    const status = message === 'Unauthorized' ? 401 : message === 'Forbidden' ? 403 : 500
    return json({ error: message }, status)
  }
})
