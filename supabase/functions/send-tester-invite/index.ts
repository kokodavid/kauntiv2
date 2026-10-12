// Sends a one-to-one beta access email only after the dashboard has approved
// the tester's seat. Resend credentials never leave this function.

import { createClient } from 'npm:@supabase/supabase-js@2'
import { seatInviteEmail } from '../_shared/emails/templates.ts'
import { sendWithResend } from '../_shared/emails/resend.ts'

const corsHeaders = {
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-origin': '*',
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, 'content-type': 'application/json', 'cache-control': 'no-store' },
})

type Invite = {
  invite_id: string
  email: string
  platform: 'android' | 'ios'
  founder_number: number
  access_url: string
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

    const from = Deno.env.get('BETA_INVITE_FROM')
    if (!from) throw new Error('Email delivery is not configured')
    const content = seatInviteEmail(invite)
    const messageId = await sendWithResend({
      from,
      to: invite.email,
      subject: content.subject,
      html: content.html,
      text: content.text,
      tags: [{ name: 'category', value: 'tester-seat-invite' }, { name: 'platform', value: invite.platform }],
    })
    await serviceClient.rpc('record_beta_tester_invite_delivery', {
      p_invite_id: inviteId,
      p_provider_message_id: messageId,
      p_error: null,
    })
    return json({ status: 'sent', provider_message_id: messageId })
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
