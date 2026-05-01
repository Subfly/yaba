import type { TocJson } from "@/bridge/toc-host-events"

export interface HeadingInMarkdown {
  /** 0-based index among non-empty headings (matches `toc-h-${n}`). */
  index: number
  level: number
  text: string
  /** Start offset of the `#` that begins the heading line. */
  from: number
}

/**
 * Scan markdown for ATX headings; `from` is the document offset of the line’s leading `#`.
 */
export function listMarkdownHeadings(md: string): HeadingInMarkdown[] {
  const headings: HeadingInMarkdown[] = []
  let i = 0
  let lineStart = 0
  let index = 0
  while (i <= md.length) {
    const lineEnd = md.indexOf("\n", i)
    const end = lineEnd === -1 ? md.length : lineEnd
    const line = md.slice(lineStart, end)
    const match = /^(\s*)(#{1,6})\s+(.+?)\s*$/.exec(line)
    if (match) {
      const level = match[2].length
      const text = match[3].trim()
      if (text.length > 0) {
        const hashesStart = lineStart + (match[1]?.length ?? 0)
        headings.push({ index, level, text, from: hashesStart })
        index += 1
      }
    }
    if (lineEnd === -1) break
    i = lineEnd + 1
    lineStart = i
  }
  return headings
}

export function buildHeadingTocFromMarkdown(md: string): TocJson | null {
  const headings = listMarkdownHeadings(md)
  if (headings.length === 0) return null

  type Item = {
    id: string
    title: string
    level: number
    children: Item[]
    extrasJson?: string | null
  }
  const root: Item[] = []
  const stack: { level: number; children: Item[] }[] = [{ level: 0, children: root }]

  for (const h of headings) {
    const id = `toc-h-${h.index}`
    const extrasJson = JSON.stringify({ from: h.from })
    const item: Item = {
      id,
      title: h.text,
      level: h.level,
      children: [],
      extrasJson,
    }
    while (stack.length > 1 && stack[stack.length - 1].level >= h.level) {
      stack.pop()
    }
    stack[stack.length - 1].children.push(item)
    stack.push({ level: h.level, children: item.children })
  }
  return { items: root }
}

export function findHeadingOffsetForTocItemId(md: string, tocItemId: string): number | null {
  const m = /^toc-h-(\d+)$/.exec(tocItemId)
  if (!m) return null
  const n = parseInt(m[1], 10)
  if (!Number.isFinite(n) || n < 0) return null
  const headings = listMarkdownHeadings(md)
  return headings[n]?.from ?? null
}
