import { reportResolvedHtml } from './report-resolved-html.ts'
import { reportResolvedText } from './report-resolved-text.ts'
import { seatInviteHtml } from './seat-invite-html.ts'
import { seatInviteText } from './seat-invite-text.ts'
import { escapeHtml, render, romanNumeral, withoutFooterPlaceholder, withoutIcon, type Vars } from './render.ts'

const iconUrl = () => Deno.env.get('EMAIL_ICON_URL') ?? 'https://kaunti47.com/assets/logo-192.png'

export function seatInviteEmail(invite: {
  email: string
  platform: 'android' | 'ios'
  founder_number: number
  access_url: string
}) {
  const vars: Vars = {
    seat_number: invite.founder_number,
    seat_roman: romanNumeral(invite.founder_number),
    platform_name: invite.platform === 'android' ? 'Android' : 'iPhone',
    is_android: invite.platform === 'android',
    show_premium: false, // held back for now
    tester_email: invite.email,
    install_url: invite.access_url,
    icon_url: iconUrl(),
  }
  const html = iconUrl() ? seatInviteHtml : withoutIcon(seatInviteHtml)
  return {
    subject: 'Your Kaunti47 beta tester seat is ready',
    html: withoutFooterPlaceholder(render(html, vars, 'html')),
    text: withoutFooterPlaceholder(render(seatInviteText, vars, 'text')),
  }
}

const categoryLabels: Record<string, string> = {
  bug: 'Bug',
  feature_idea: 'Feature idea',
  content_issue: 'Content issue',
  performance: 'Performance',
  usability: 'Usability',
}

export function reportResolvedEmail(report: {
  report_number: string
  report_title: string
  category: string
  team_reply: string | null
  resolved_at: string | null
  first_name: string | null
}) {
  const reportsUrl = Deno.env.get('FEEDBACK_REPORTS_URL') ?? ''
  const date = new Date(report.resolved_at ?? Date.now()).toLocaleDateString('en-GB', {
    day: 'numeric', month: 'short', year: 'numeric', timeZone: 'Africa/Nairobi',
  })
  const reply = report.team_reply?.trim() ?? ''
  const base: Vars = {
    first_name: report.first_name || 'there',
    report_number: report.report_number,
    report_title: report.report_title,
    category: categoryLabels[report.category] ?? report.category,
    resolved_date: date,
    team_reply: reply,
    deep_link: Boolean(reportsUrl),
    reports_url: reportsUrl,
    icon_url: iconUrl(),
  }
  const htmlVars: Vars = { ...base, team_reply: escapeHtml(reply).replaceAll('\n', '<br>') }
  const html = iconUrl() ? reportResolvedHtml : withoutIcon(reportResolvedHtml)
  return {
    subject: `${report.report_number} is resolved`,
    html: withoutFooterPlaceholder(render(html, htmlVars, 'html', ['team_reply'])),
    text: withoutFooterPlaceholder(render(reportResolvedText, base, 'text')),
  }
}
