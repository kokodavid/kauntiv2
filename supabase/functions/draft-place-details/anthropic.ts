import { SUBMIT_TOOL, SYSTEM_PROMPT } from './prompt.ts'

type Block = { type: string; [key: string]: unknown }
export type Usage = { input: number; output: number; searches: number }
export type RawDraft = Record<string, unknown>

const MAX_TURNS = 6

// Runs the research loop and returns the input passed to submit_draft.
export async function researchPlace(
  apiKey: string,
  model: string,
  query: string,
  countyHint: string | null,
): Promise<{ draft: RawDraft | null; usage: Usage }> {
  const usage: Usage = { input: 0, output: 0, searches: 0 }
  const userText = countyHint
    ? `Research this place and draft the form: ${query} (admin says it is in ${countyHint} county; verify).`
    : `Research this place and draft the form: ${query}`
  const messages: { role: string; content: unknown }[] = [{ role: 'user', content: userText }]

  for (let turn = 0; turn < MAX_TURNS; turn++) {
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
        system: SYSTEM_PROMPT,
        tools: [
          { type: 'web_search_20250305', name: 'web_search', max_uses: 6 },
          { type: 'web_fetch_20250910', name: 'web_fetch', max_uses: 4 },
          SUBMIT_TOOL,
        ],
        messages,
      }),
    })
    if (!response.ok) {
      console.error('Anthropic error', response.status, await response.text())
      throw new Error('AI request failed')
    }
    const data = await response.json()
    usage.input += data.usage?.input_tokens ?? 0
    usage.output += data.usage?.output_tokens ?? 0
    usage.searches += data.usage?.server_tool_use?.web_search_requests ?? 0

    const content = (data.content ?? []) as Block[]
    const submit = content.find((b) => b.type === 'tool_use' && b.name === 'submit_draft')
    if (submit) return { draft: submit.input as RawDraft, usage }

    if (data.stop_reason === 'pause_turn') {
      messages.push({ role: 'assistant', content })
      continue
    }
    if (data.stop_reason === 'tool_use') {
      // Any other client tool call is unexpected; nudge the model to finish.
      messages.push({ role: 'assistant', content })
      messages.push({ role: 'user', content: 'Call submit_draft now.' })
      continue
    }
    messages.push({ role: 'assistant', content })
    messages.push({ role: 'user', content: 'Finish by calling submit_draft.' })
  }
  return { draft: null, usage }
}
