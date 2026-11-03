import { render, withoutFooterPlaceholder, withoutIcon, type Vars } from './render.ts'
import { testerInviteHtml } from './tester-invite-html.ts'
import { testerInviteText } from './tester-invite-text.ts'

// `Deno` is missing when the tests run under Node.
const iconUrl = () => (globalThis as { Deno?: typeof Deno }).Deno?.env.get('EMAIL_ICON_URL') ?? 'https://kaunti47.com/assets/logo-192.png'

// The waitlist invitation: the same design as the seat invitation, without a
// seat number or any seat or premium promise.
export function testerInviteEmail(invite: { email: string; platform: 'android' | 'ios'; access_url: string }) {
  const vars: Vars = {
    is_android: invite.platform === 'android',
    tester_email: invite.email,
    install_url: invite.access_url,
    icon_url: iconUrl(),
  }
  const html = iconUrl() ? testerInviteHtml : withoutIcon(testerInviteHtml)
  return {
    subject: "You're invited to test Kaunti47",
    html: withoutFooterPlaceholder(render(html, vars, 'html')),
    text: withoutFooterPlaceholder(render(testerInviteText, vars, 'text')),
  }
}
