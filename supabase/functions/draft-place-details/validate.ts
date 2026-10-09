import type { RawDraft } from './anthropic.ts'

export const SUMMARY_MAX = 200

const HEDGES =
  /(no source|couldn't find|could not find|according to|unconfirmed|sources? (disagree|differ)|check before|i found|research)/i

const str = (v: unknown) => (typeof v === 'string' ? v.trim() : '')

export function clampSummary(text: string): string {
  if (text.length <= SUMMARY_MAX) return text
  const cut = text.slice(0, SUMMARY_MAX)
  const sentence = Math.max(cut.lastIndexOf('. '), cut.lastIndexOf('.'))
  if (sentence > 60) return cut.slice(0, sentence + 1)
  const space = cut.lastIndexOf(' ')
  return cut.slice(0, space > 0 ? space : SUMMARY_MAX - 1).replace(/[,;:\s]+$/, '') + '.'
}

export type CleanDraft = {
  name: string
  type: string
  county_name: string
  summary: string
  description: string
  source: string
  source_url: string
  licence: string
  lat: number | null
  lng: number | null
  county_confidence: string
  coordinate_confidence: string
  notes: string[]
  sources: { title: string; url: string }[]
}

export function cleanDraft(raw: RawDraft): CleanDraft {
  const notes = Array.isArray(raw.notes) ? raw.notes.map(str).filter(Boolean) : []
  let summary = str(raw.summary)
  const description = str(raw.description).replace(/[*#_`]/g, '')
  if (summary.length > SUMMARY_MAX) summary = clampSummary(summary)
  if (HEDGES.test(summary) || HEDGES.test(description)) {
    notes.push('Copy may contain research wording; please read it before saving.')
  }

  const lat = typeof raw.lat === 'number' ? raw.lat : null
  const lng = typeof raw.lng === 'number' ? raw.lng : null
  const inKenya =
    lat !== null && lng !== null && lat >= -4.8 && lat <= 5.1 && lng >= 33.8 && lng <= 41.95
  if ((lat !== null || lng !== null) && !inKenya) notes.push('Coordinates fell outside Kenya and were dropped.')

  const sources = Array.isArray(raw.sources)
    ? (raw.sources as Record<string, unknown>[])
        .map((s) => ({ title: str(s.title), url: str(s.url) }))
        .filter((s) => /^https?:\/\//.test(s.url))
        .slice(0, 8)
    : []
  const sourceUrl = str(raw.source_url)

  return {
    name: str(raw.name),
    type: str(raw.type).toLowerCase(),
    county_name: str(raw.county_name),
    summary,
    description,
    source: str(raw.source),
    source_url: /^https?:\/\//.test(sourceUrl) ? sourceUrl : '',
    licence: str(raw.licence),
    lat: inKenya ? lat : null,
    lng: inKenya ? lng : null,
    county_confidence: str(raw.county_confidence) || 'medium',
    coordinate_confidence: inKenya ? str(raw.coordinate_confidence) || 'landmark' : 'none',
    notes,
    sources,
  }
}
