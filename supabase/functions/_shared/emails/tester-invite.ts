import { render } from './render.ts'

export function testerInviteEmail(invite: { email: string; platform: 'android' | 'ios'; access_url: string }) {
  const vars = {
    tester_email: invite.email,
    install_url: invite.access_url,
    is_android: invite.platform === 'android',
  }
  const text = `You're invited to test Kaunti47

Thanks for joining our waitlist. You can now try the Kaunti47 beta.

{{#if is_android}}Open the link below in Chrome, signed in to Google with {{tester_email}}.
Join the test, then tap "Download test app" and install from Google Play using the same account.
{{else}}Install Apple TestFlight from the App Store, then open the link below on your iPhone and accept the invitation to install Kaunti47.
{{/if}}
{{install_url}}

Sign in to Kaunti47 with {{tester_email}}.

Share your feedback in Profile > Beta feedback.
Need help? Email hello@kaunti47.com.

The Kaunti47 team
You received this invitation because you joined the Kaunti47 waitlist.`
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="margin:0;background:#F5F6F8;font-family:Arial,sans-serif;color:#18181B">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:24px 16px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#FFFFFF"><tr><td style="padding:28px">
<p style="color:#0A84FF;font-weight:bold">KAUNTI47 BETA</p>
<h1 style="font-size:26px;line-height:1.3">You're invited to test Kaunti47</h1>
<p>Thanks for joining our waitlist. You can now try the Kaunti47 beta.</p>
{{#if is_android}}<p>Open the link below in Chrome, signed in to Google with <strong>{{tester_email}}</strong>.</p>
<p>Join the test, then tap <strong>Download test app</strong> and install from Google Play using the same account.</p>
{{else}}<p>Install Apple TestFlight from the App Store, then open the link below on your iPhone and accept the invitation to install Kaunti47.</p>{{/if}}
<p><a href="{{install_url}}" style="color:#0A84FF;font-weight:bold">Open Kaunti47 beta access</a></p>
<p>Sign in to Kaunti47 with <strong>{{tester_email}}</strong>.</p>
<p>Share your feedback in Profile &gt; Beta feedback.</p>
<p>Need help? Email <a href="mailto:hello@kaunti47.com">hello@kaunti47.com</a>.</p>
<p>The Kaunti47 team</p><p style="font-size:12px;color:#71717A">You received this invitation because you joined the Kaunti47 waitlist.</p>
</td></tr></table></td></tr></table></body></html>`
  return { subject: "You're invited to test Kaunti47", html: render(html, vars, 'html'), text: render(text, vars, 'text') }
}
