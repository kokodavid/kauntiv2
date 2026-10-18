// Sends the "your report is resolved" email for reports waiting in the queue.
// The dashboard calls this after marking a report resolved, without waiting
// for it, so a slow or failing email never blocks anyone. Calling it again
// retries failures. Does nothing while invite delivery is switched off.

import { createClient } from 'npm:@supabase/supabase-js@2'
import { reportResolvedEmail } from '../_shared/emails/templates.ts'
import { SUPPORT_EMAIL, sendWithResend } from '../_shared/emails/resend.ts'

const corsHeaders = {
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-origin': '*',
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, 'content-type': 'application/json', 'cache-control': 'no-store' },
})

type Queued = {
  report_id: string
  report_number: string
  report_title: string
  category: string
  team_reply: string | null
  resolved_at: string | null
  email: string | null
  first_name: string | null
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
  return createClient(url, serviceKey, { auth: { persistSession: false } })
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  try {
    const service = await requireAdmin(request)
    const from = Deno.env.get('BETA_INVITE_FROM')
    if (!from) throw new Error('Email delivery is not configured')

    const { data, error } = await service.rpc('claim_feedback_resolved_emails', { p_limit: 10 })
    if (error) throw new Error(error.message)
    const queued = (data ?? []) as Queued[]

    let sent = 0
    let failed = 0
    for (const item of queued) {
      if (!item.email) {
        await service.rpc('record_feedback_resolved_email', {
          p_report_id: item.report_id, p_provider_message_id: null,
          p_error: 'No email address on file', p_skipped: true,
        })
        continue
      }
      try {
        const content = reportResolvedEmail(item)
        const messageId = await sendWithResend({
          from,
          to: item.email,
          replyTo: SUPPORT_EMAIL,
          subject: content.subject,
          html: content.html,
          text: content.text,
          tags: [{ name: 'category', value: 'feedback-resolved' }],
        })
        await service.rpc('record_feedback_resolved_email', {
          p_report_id: item.report_id, p_provider_message_id: messageId, p_error: null, p_skipped: false,
        })
        sent += 1
      } catch (sendError) {
        failed += 1
        await service.rpc('record_feedback_resolved_email', {
          p_report_id: item.report_id, p_provider_message_id: null,
          p_error: sendError instanceof Error ? sendError.message : 'Send failed', p_skipped: false,
        })
      }
    }
    return json({ claimed: queued.length, sent, failed })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Could not send'
    return json({ error: message }, message === 'Unauthorized' ? 401 : message === 'Forbidden' ? 403 : 500)
  }
})
