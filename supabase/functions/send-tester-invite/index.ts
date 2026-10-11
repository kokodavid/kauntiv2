// Sends a one-to-one beta access email only after the dashboard has approved
// the tester's seat. Resend credentials never leave this function.

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

const escapeHtml = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;')

type Invite = {
  invite_id: string
  email: string
  platform: 'android' | 'ios'
  founder_number: number
  access_url: string
}

function message(invite: Invite) {
  const platform = invite.platform === 'android' ? 'Android' : 'iPhone'
  const instructions = invite.platform === 'android'
    ? `
      <ol>
        <li>Open the link below while signed in to Google Play with <strong>${escapeHtml(invite.email)}</strong>.</li>
        <li>Choose <strong>Become a tester</strong>.</li>
        <li>Install or update Kaunti47 from Google Play.</li>
      </ol>`
    : `
      <ol>
        <li>Install Apple TestFlight from the App Store if you do not already have it.</li>
        <li>Open the link below on your iPhone.</li>
        <li>Accept the Kaunti47 invitation in TestFlight, then install the app.</li>
      </ol>`
  const accessUrl = escapeHtml(invite.access_url)
  const html = `<!doctype html>
<html><body style="margin:0;background:#f5f7fb;color:#17202a;font-family:Arial,sans-serif">
  <main style="max-width:600px;margin:0 auto;padding:36px 24px">
    <p style="margin:0 0 8px;color:#1683ff;font-weight:700">KAUNTI47 BETA</p>
    <h1 style="margin:0 0 18px;font-size:28px">Your tester seat is ready</h1>
    <p>You've been approved for tester seat <strong>${invite.founder_number}</strong> on ${platform}.</p>
    ${instructions}
    <p style="margin:28px 0"><a href="${accessUrl}" style="display:inline-block;padding:14px 20px;border-radius:10px;background:#1683ff;color:#fff;font-weight:700;text-decoration:none">Open Kaunti47 beta access</a></p>
    <p style="color:#59636e;font-size:14px">If the button does not open, copy this address into your browser:<br><a href="${accessUrl}">${accessUrl}</a></p>
    <p style="color:#59636e;font-size:14px">Need help? Reply to this email and the Kaunti47 team will help you get set up.</p>
  </main>
</body></html>`
  const text = invite.platform === 'android'
    ? `Your Kaunti47 tester seat ${invite.founder_number} is ready. Open ${invite.access_url} while signed in to Google Play with ${invite.email}, choose Become a tester, then install or update Kaunti47 from Google Play.`
    : `Your Kaunti47 tester seat ${invite.founder_number} is ready. Install TestFlight if needed, then open ${invite.access_url} on your iPhone, accept the Kaunti47 invitation, and install the app.`
  return { html, text }
}

async function requireAdmin(request: Request) {
  const url = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('authorization')
  if (!url || !anonKey || !serviceKey || !authorization) throw new Error('Not configured')
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } })
  const { data: user, error: userError } = await userClient.auth.getUser()
  if (userError || !user.user) throw new Error('Unauthorized')
  const { data: role, error: roleError } = await userClient.rpc('current_admin_role')
  if (roleError || !['owner', 'admin'].includes(role as string)) throw new Error('Forbidden')
  return { userClient, serviceClient: createClient(url, serviceKey, { auth: { persistSession: false } }) }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  let inviteId: string | null = null
  try {
    const body = await request.json() as { signup_id?: unknown }
    if (typeof body.signup_id !== 'string' || !body.signup_id.trim()) return json({ error: 'signup_id is required' }, 400)
    const { userClient, serviceClient } = await requireAdmin(request)
    const { data, error } = await userClient.rpc('claim_beta_tester_invite_dashboard', { p_signup_id: body.signup_id })
    if (error) return json({ error: error.message }, error.code === '42501' ? 403 : 400)
    const invite = (data as Invite[] | null)?.[0]
    if (!invite) return json({ error: 'Could not prepare invitation' }, 500)
    inviteId = invite.invite_id

    const resendKey = Deno.env.get('RESEND_API_KEY')
    const from = Deno.env.get('BETA_INVITE_FROM')
    if (!resendKey || !from) throw new Error('Email delivery is not configured')
    const content = message(invite)
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { authorization: `Bearer ${resendKey}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        from,
        to: [invite.email],
        subject: 'Your Kaunti47 beta tester seat is ready',
        html: content.html,
        text: content.text,
        tags: [{ name: 'category', value: 'tester-seat-invite' }, { name: 'platform', value: invite.platform }],
      }),
    })
    const payload = await response.json().catch(() => ({})) as { id?: string; message?: string }
    if (!response.ok || !payload.id) throw new Error(payload.message ?? 'Email provider rejected the invitation')
    await serviceClient.rpc('record_beta_tester_invite_delivery', {
      p_invite_id: inviteId,
      p_provider_message_id: payload.id,
      p_error: null,
    })
    return json({ status: 'sent', provider_message_id: payload.id })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Could not send invitation'
    if (inviteId) {
      const url = Deno.env.get('SUPABASE_URL')
      const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
      if (url && serviceKey) {
        const serviceClient = createClient(url, serviceKey, { auth: { persistSession: false } })
        await serviceClient.rpc('record_beta_tester_invite_delivery', {
          p_invite_id: inviteId,
          p_provider_message_id: null,
          p_error: message,
        })
      }
    }
    return json({ error: message }, message === 'Unauthorized' ? 401 : message === 'Forbidden' ? 403 : 500)
  }
})
