// Run with Node 22+ (native TypeScript support). No provider calls or emails.
import assert from 'node:assert/strict'
import { test } from 'node:test'
import { testerInviteEmail } from '../functions/_shared/emails/tester-invite.ts'

for (const platform of ['android', 'ios']) {
  test(`${platform}: general invitation has correct install instructions and no seat promise`, () => {
    const content = testerInviteEmail({
      email: 'a<&@example.invalid', platform,
      access_url: 'https://example.invalid/?a=1&b=2',
    })
    assert.doesNotMatch(content.html + content.text, /founder|premium|seat|\{\{/i)
    assert.match(content.html, /a&lt;&amp;@example.invalid/)
    assert.match(content.html, /a=1&amp;b=2/)
    assert.match(content.text, platform === 'android' ? /Google Play/ : /TestFlight/)
    assert.doesNotMatch(content.text, platform === 'android' ? /TestFlight/ : /Google Play/)
  })
}
