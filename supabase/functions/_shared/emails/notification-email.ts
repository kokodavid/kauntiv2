// Short "something happened" email used as the fallback when a push cannot
// reach someone (no device, notifications off, dead token). Plain on purpose:
// the same title and body the push would have shown, plus one way back in.

import { escapeHtml } from './render.ts'

export function notificationEmail(input: {
  title: string
  body: string
  first_name: string | null
  kind: string
  app_url: string
  off_url: string
}) {
  const name = input.first_name || 'there'
  const cta = input.app_url
    ? `<tr><td style="padding:24px 0 0 0;"><a href="${escapeHtml(input.app_url)}" style="display:inline-block;background:#0A84FF;color:#ffffff;text-decoration:none;font-weight:600;font-size:16px;padding:13px 22px;border-radius:12px;">Open Kaunti47</a></td></tr>`
    : ''
  const reason = input.kind === 'announcement'
    ? 'You received this because announcements are on in your Kaunti47 settings and we could not reach you in the app.'
    : 'You received this because we could not reach you in the app.'
  const off = input.kind === 'announcement' && input.off_url
    ? `<br><a href="${escapeHtml(input.off_url)}" style="color:#0A84FF;">Turn announcements off</a> or open Profile &gt; Notifications in the app.`
    : ''
  const html = `<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark"><meta name="supported-color-schemes" content="light dark">
<title>${escapeHtml(input.title)}</title>
<style>@media (prefers-color-scheme: dark){.bg{background:#0B0D12!important}.card{background:#16181F!important}.ink{color:#F4F4F5!important}.muted{color:#B4B4BC!important}}</style>
</head><body class="bg" style="margin:0;padding:0;background:#F5F6F8;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="bg" style="background:#F5F6F8;"><tr><td align="center" style="padding:32px 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;">
<tr><td class="ink" style="padding:0 8px 16px 8px;font-family:Inter,-apple-system,Segoe UI,Helvetica,Arial,sans-serif;font-size:17px;font-weight:700;color:#181818;">Kaunti47</td></tr>
<tr><td class="card" style="background:#ffffff;border-radius:20px;padding:32px 28px;font-family:Inter,-apple-system,Segoe UI,Helvetica,Arial,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0">
<tr><td class="ink" style="font-size:24px;line-height:30px;font-weight:700;color:#181818;padding-bottom:12px;">${escapeHtml(input.title)}</td></tr>
<tr><td class="muted" style="font-size:16px;line-height:24px;color:#52525B;">Hi ${escapeHtml(name)}, ${escapeHtml(input.body)}</td></tr>
${cta}
</table></td></tr>
<tr><td class="muted" style="padding:20px 8px 0 8px;font-family:Inter,-apple-system,Segoe UI,Helvetica,Arial,sans-serif;font-size:12px;line-height:18px;color:#71717A;">${reason}${off}<br>Questions? Email <a href="mailto:hello@kaunti47.com" style="color:#0A84FF;">hello@kaunti47.com</a>.</td></tr>
</table></td></tr></table></body></html>`
  const text = `${input.title}\n\nHi ${name}, ${input.body}\n\n${input.app_url ? `Open Kaunti47: ${input.app_url}\n\n` : ''}--\n${reason}${input.kind === 'announcement' ? '\nTurn announcements off in the app: Profile > Notifications.' : ''}\nQuestions? Email hello@kaunti47.com.\n`
  return { subject: input.title, html, text }
}
