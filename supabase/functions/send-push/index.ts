// Sends queued push events (and the email fallback for them).
// Called every minute by pg_cron/pg_net with the service role key, and by the
// dashboard right after "send test to my phone". Safe to call repeatedly: work
// is claimed in the database, caps, quiet hours and opt-outs are enforced there.

import { createClient } from 'npm:@supabase/supabase-js@2'
import { SUPPORT_EMAIL, sendWithResend } from '../_shared/emails/resend.ts'
import { notificationEmail } from '../_shared/emails/notification-email.ts'
import { loadServiceAccount, sendToToken } from './fcm.ts'

const corsHeaders = {
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
  'access-control-allow-origin': '*',
}
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, 'content-type': 'application/json', 'cache-control': 'no-store' },
})

type Claimed = {
  event_id: string
  user_id: string
  kind: string
  delivery: 'push' | 'email'
  title: string
  body: string
  dest_kind: string
  dest_id: string | null
  tokens: string[]
  email: string | null
  first_name: string | null
}

// The cron job sends the service role key; the dashboard sends an owner,
// admin or editor session.
async function authorise(request: Request) {
  const url = Deno.env.get('SUPABASE_URL')
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const authorization = request.headers.get('authorization')
  if (!url || !anonKey || !serviceKey || !authorization) throw new Error('Not configured')
  const service = createClient(url, serviceKey, { auth: { persistSession: false } })
  if (authorization === `Bearer ${serviceKey}`) return service
  const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authorization } } })
  const { data: user, error } = await userClient.auth.getUser()
  if (error || !user.user) throw new Error('Unauthorized')
  const { data: role } = await userClient.rpc('current_admin_role')
  if (!['owner', 'admin', 'editor', 'moderator'].includes(role as string)) throw new Error('Forbidden')
  return service
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405)

  try {
    const service = await authorise(request)

    // Turn any campaign whose time has come into per-person events first.
    await service.rpc('run_due_push_campaigns')

    const { data, error } = await service.rpc('claim_push_events', { p_limit: 50 })
    if (error) throw new Error(error.message)
    const events = (data ?? []) as Claimed[]

    const from = Deno.env.get('BETA_INVITE_FROM')
    const appUrl = Deno.env.get('APP_OPEN_URL') ?? ''
    const offUrl = Deno.env.get('ANNOUNCEMENTS_OFF_URL') ?? ''
    let account: ReturnType<typeof loadServiceAccount> | null = null

    let sent = 0
    let failed = 0
    // 20 at a time keeps a burst well inside the function time limit.
    for (let i = 0; i < events.length; i += 20) {
      await Promise.all(events.slice(i, i + 20).map(async (event) => {
        try {
          if (event.delivery === 'email') {
            if (!from || !event.email) throw new Error('Email is not configured')
            const content = notificationEmail({
              title: event.title, body: event.body, first_name: event.first_name,
              kind: event.kind, app_url: appUrl, off_url: offUrl,
            })
            const messageId = await sendWithResend({
              from, to: event.email, replyTo: SUPPORT_EMAIL,
              subject: content.subject, html: content.html, text: content.text,
              tags: [{ name: 'category', value: `notification-${event.kind}` }],
            })
            await service.rpc('record_push_result', {
              p_event_id: event.event_id, p_ok: true, p_message_id: messageId,
            })
            sent += 1
            return
          }

          account ??= loadServiceAccount()
          const results = await Promise.all(event.tokens.map((token) => sendToToken(account!, token, {
            eventId: event.event_id, title: event.title, body: event.body, kind: event.kind,
            destKind: event.dest_kind ?? 'home', destId: event.dest_id,
          })))
          // One event can go to several phones and counts as sent if any
          // accepts it, so a failing phone would otherwise leave no trace.
          // Log each result (only the last 6 characters of the token).
          for (const r of results) {
            console.log(JSON.stringify({
              event: event.event_id, kind: event.kind, token: `…${r.token.slice(-6)}`,
              ok: r.ok, dead: r.dead, error: r.error ?? null,
            }))
          }
          const dead = results.filter((r) => r.dead).map((r) => r.token)
          const ok = results.some((r) => r.ok)
          const allDead = results.length > 0 && results.every((r) => !r.ok && r.dead)
          await service.rpc('record_push_result', {
            p_event_id: event.event_id,
            p_ok: ok,
            p_error: ok ? null : (results.find((r) => !r.ok)?.error ?? 'No device accepted it'),
            p_dead_tokens: dead,
            p_message_id: results.find((r) => r.ok)?.id ?? null,
            p_permanent: allDead,
          })
          if (ok) sent += 1
          else failed += 1
        } catch (sendError) {
          failed += 1
          await service.rpc('record_push_result', {
            p_event_id: event.event_id, p_ok: false,
            p_error: sendError instanceof Error ? sendError.message : 'Send failed',
            p_permanent: false,
          })
        }
      }))
    }
    return json({ claimed: events.length, sent, failed })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Could not send'
    return json({ error: message }, message === 'Unauthorized' ? 401 : message === 'Forbidden' ? 403 : 500)
  }
})
