// FCM HTTP v1 sender. The service account JSON lives in the
// FCM_SERVICE_ACCOUNT secret (one per Supabase environment, matching its
// Firebase project). Tokens FCM reports as unregistered are returned so the
// caller can delete them.

type ServiceAccount = { project_id: string; client_email: string; private_key: string }

let cached: { token: string; expires: number } | null = null

const b64url = (input: ArrayBuffer | string) => {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : new Uint8Array(input)
  let bin = ''
  bytes.forEach((b) => { bin += String.fromCharCode(b) })
  return btoa(bin).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '')
}

export function loadServiceAccount(): ServiceAccount {
  const raw = Deno.env.get('FCM_SERVICE_ACCOUNT')
  if (!raw) throw new Error('Push is not configured')
  return JSON.parse(raw) as ServiceAccount
}

async function accessToken(account: ServiceAccount) {
  if (cached && cached.expires > Date.now() + 60_000) return cached.token
  const now = Math.floor(Date.now() / 1000)
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const claims = b64url(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))
  const pem = account.private_key.replace(/-----[^-]+-----/g, '').replace(/\s/g, '')
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const key = await crypto.subtle.importKey(
    'pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'],
  )
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`))
  const assertion = `${header}.${claims}.${b64url(signature)}`
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  })
  const body = await response.json() as { access_token?: string; expires_in?: number }
  if (!response.ok || !body.access_token) throw new Error('Could not authorise with Firebase')
  cached = { token: body.access_token, expires: Date.now() + (body.expires_in ?? 3600) * 1000 }
  return cached.token
}

export type PushMessage = {
  eventId: string
  title: string
  body: string
  kind: string
  destKind: string
  destId: string | null
}

export type TokenResult = { token: string; ok: boolean; dead: boolean; error?: string; id?: string }

export async function sendToToken(account: ServiceAccount, token: string, m: PushMessage): Promise<TokenResult> {
  const access = await accessToken(account)
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
    {
      method: 'POST',
      headers: { authorization: `Bearer ${access}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: m.title, body: m.body },
          // The app resolves these to a route; unknown values open Home.
          data: {
            event_id: m.eventId,
            kind: m.kind,
            dest_kind: m.destKind,
            dest_id: m.destId ?? '',
          },
          android: { priority: 'HIGH', notification: { channel_id: m.kind === 'announcement' ? 'announcements' : 'reviews' } },
          apns: { headers: { 'apns-priority': '10' }, payload: { aps: { sound: 'default' } } },
        },
      }),
    },
  )
  const payload = await response.json().catch(() => ({})) as {
    name?: string
    error?: { status?: string; message?: string }
  }
  if (response.ok) return { token, ok: true, dead: false, id: payload.name }
  const status = payload.error?.status ?? ''
  const dead = status === 'UNREGISTERED' || status === 'NOT_FOUND' || status === 'INVALID_ARGUMENT'
  return { token, ok: false, dead, error: payload.error?.message ?? status ?? 'FCM error' }
}
