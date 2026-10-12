export async function sendWithResend(input: {
  from: string
  to: string
  subject: string
  html: string
  text: string
  tags: { name: string; value: string }[]
  replyTo?: string
}) {
  const key = Deno.env.get('RESEND_API_KEY')
  if (!key) throw new Error('Email delivery is not configured')
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { authorization: `Bearer ${key}`, 'content-type': 'application/json' },
    body: JSON.stringify({
      from: input.from,
      to: [input.to],
      subject: input.subject,
      html: input.html,
      text: input.text,
      tags: input.tags,
      ...(input.replyTo ? { reply_to: input.replyTo } : {}),
    }),
  })
  const payload = await response.json().catch(() => ({})) as { id?: string; message?: string }
  if (!response.ok || !payload.id) throw new Error(payload.message ?? 'Email provider rejected the message')
  return payload.id
}
