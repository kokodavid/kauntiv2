// Tiny renderer for the email templates: {{name}} (escaped), {{#if name}}…{{else}}…{{/if}}
// (not nested). Values listed in `raw` are inserted as-is, so only pass
// HTML you built and escaped yourself.

export const escapeHtml = (value: string) => value
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;')

export type Vars = Record<string, string | number | boolean | null | undefined>

export function render(template: string, vars: Vars, mode: 'html' | 'text', raw: string[] = []) {
  const withBlocks = template.replace(
    /\{\{#if (\w+)\}\}([\s\S]*?)(?:\{\{else\}\}([\s\S]*?))?\{\{\/if\}\}/g,
    (_m, key: string, yes: string, no: string | undefined) => (vars[key] ? yes : (no ?? '')),
  )
  return withBlocks.replace(/\{\{(\w+)\}\}/g, (_m, key: string) => {
    const value = vars[key]
    if (value === null || value === undefined || value === false) return ''
    const text = String(value)
    return mode === 'html' && !raw.includes(key) ? escapeHtml(text) : text
  })
}

// Removes the small logo image when no hosted icon URL is configured, so the
// header falls back to the blue square instead of a broken image.
export const withoutIcon = (html: string) => html.replace(/<img [^>]*\{\{icon_url\}\}[^>]*>/, '')

export const romanNumeral = (n: number) => {
  const map: [number, string][] = [[40, 'XL'], [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'], [1, 'I']]
  let rest = n
  let out = ''
  for (const [value, symbol] of map) {
    while (rest >= value) { out += symbol; rest -= value }
  }
  return out
}

// The footer company/postal line is not decided yet; drop the placeholder so it
// never reaches a tester. Replace this once the line is confirmed.
export const withoutFooterPlaceholder = (body: string) => body
  .replace(/<span[^>]*>\[Company or postal line: to be confirmed\]<\/span>/, '')
  .replace(/\n?\[Company or postal line: to be confirmed\]/, '')
