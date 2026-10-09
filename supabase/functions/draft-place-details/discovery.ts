type Block = { type: string; [key: string]: unknown }

export type DiscoveryUsage = { input: number; output: number; searches: number }
export type DiscoverySuggestion = {
  name: string
  type: string
  reason: string
  source_title: string
  source_url: string
}

const DISCOVERY_TOOL = {
  name: 'submit_discoveries',
  description: 'Submit a short, independently researched list of Kenyan place leads.',
  input_schema: {
    type: 'object',
    properties: {
      suggestions: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            type: { type: 'string' },
            reason: { type: 'string' },
            source_title: { type: 'string' },
            source_url: { type: 'string' },
          },
          required: ['name', 'type', 'reason', 'source_url'],
        },
      },
      notes: { type: 'array', items: { type: 'string' } },
    },
    required: ['suggestions'],
  },
}

const str = (value: unknown) => (typeof value === 'string' ? value.trim() : '')

export function cleanSuggestions(value: unknown, limit: number): DiscoverySuggestion[] {
  if (!Array.isArray(value)) return []
  const seen = new Set<string>()
  return value.flatMap((item) => {
    if (!item || typeof item !== 'object') return []
    const row = item as Record<string, unknown>
    const name = str(row.name)
    const source_url = str(row.source_url)
    const key = name.toLowerCase()
    if (name.length < 3 || name.length > 120 || !/^https?:\/\//.test(source_url) || seen.has(key)) return []
    seen.add(key)
    return [{
      name,
      type: str(row.type).toLowerCase() || 'place',
      reason: str(row.reason).slice(0, 240),
      source_title: str(row.source_title),
      source_url,
    }]
  }).slice(0, limit)
}

export async function discoverPlaces(
  apiKey: string,
  model: string,
  countyName: string,
  theme: string,
  leadUrl: string | null,
  limit: number,
): Promise<{ suggestions: DiscoverySuggestion[]; notes: string[]; usage: DiscoveryUsage }> {
  const usage: DiscoveryUsage = { input: 0, output: 0, searches: 0 }
  const leadInstruction = leadUrl
    ? `An optional discovery lead is ${leadUrl}. You may inspect it only to find names. Do not copy its text, images, summaries, or claims.`
    : 'There is no supplied discovery page.'
  const prompt = `Discover up to ${limit} distinctive visitor places in ${countyName} County, Kenya${theme ? ` for this focus: ${theme}` : ''}.

Use web_search broadly and cross-check candidates with independent sources such as official agencies, county tourism, Wikidata/Wikipedia, conservation organisations, or operators. ${leadInstruction}

Return only real, visitable Kenyan places likely useful in Kaunti47. Include a short original reason for each, but do not draft public app copy. Give one supporting URL per suggestion. Exclude generic towns, duplicate names, places outside ${countyName} County, and entries with weak evidence. Do not use a lead page as a supporting source unless it is itself authoritative.

Finish by calling submit_discoveries exactly once.`
  const messages: { role: string; content: unknown }[] = [{ role: 'user', content: prompt }]

  for (let turn = 0; turn < 6; turn++) {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': 'web-fetch-2025-09-10',
      },
      body: JSON.stringify({
        model,
        max_tokens: 4096,
        tools: [
          { type: 'web_search_20250305', name: 'web_search', max_uses: 8 },
          { type: 'web_fetch_20250910', name: 'web_fetch', max_uses: 4 },
          DISCOVERY_TOOL,
        ],
        messages,
      }),
    })
    if (!response.ok) {
      console.error('Anthropic discovery error', response.status, await response.text())
      throw new Error('AI request failed')
    }
    const data = await response.json()
    usage.input += data.usage?.input_tokens ?? 0
    usage.output += data.usage?.output_tokens ?? 0
    usage.searches += data.usage?.server_tool_use?.web_search_requests ?? 0
    const content = (data.content ?? []) as Block[]
    const submit = content.find((block) => block.type === 'tool_use' && block.name === 'submit_discoveries')
    if (submit) {
      const result = submit.input as Record<string, unknown>
      return {
        suggestions: cleanSuggestions(result.suggestions, limit),
        notes: Array.isArray(result.notes) ? result.notes.map(str).filter(Boolean).slice(0, 6) : [],
        usage,
      }
    }
    messages.push({ role: 'assistant', content })
    messages.push({ role: 'user', content: 'Finish by calling submit_discoveries.' })
  }
  return { suggestions: [], notes: ['The AI did not return a candidate list.'], usage }
}
