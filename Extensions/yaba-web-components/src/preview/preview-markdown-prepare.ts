/**
 * Prepares Markdown for ReactMarkdown: replaces `==…==` highlights with annotated `<mark>` HTML,
 * and collects task-list checkbox offsets for native toggling (preview tap → markdown patch).
 */
import {
  YABA_DEFAULT_HIGHLIGHT_HEX_DIGITS,
  YABA_HIGHLIGHT_BACKGROUND_ALPHA,
} from "@/theme/yaba-accent-palette"

const COLOR_TOKEN_PREFIX = /^\{\s*#([0-9a-fA-F]{6})\s*\}/

export type PreviewTaskToggleRegion = {
  /** UTF-16 index of `[` in `- [ ]` / `* [ ]` task lines. */
  bracketOpen: number
}

export type PreviewHighlightRegion = {
  syntaxStart: number
  syntaxEnd: number
  innerStart: number
  innerEnd: number
  /** Lowercase hex without `#`, or null for plain `==inner==`. */
  hexDigits: string | null
}

function hexToRgb(hexDigits: string): { r: number; g: number; b: number } | null {
  const h = hexDigits.toLowerCase()
  if (!/^[0-9a-f]{6}$/.test(h)) return null
  return {
    r: Number.parseInt(h.slice(0, 2), 16),
    g: Number.parseInt(h.slice(2, 4), 16),
    b: Number.parseInt(h.slice(4, 6), 16),
  }
}

function rgbaBackground(hexDigits: string | null, alpha: number): string {
  const digits = hexDigits ?? YABA_DEFAULT_HIGHLIGHT_HEX_DIGITS
  const rgb = hexToRgb(digits)
  if (!rgb) return `rgba(255, 204, 0, ${alpha})`
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`
}

function escapeHighlightInner(s: string): string {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

function findClosingDoubleEquals(md: string, from: number, max: number): number {
  let pos = from
  while (pos + 1 <= max) {
    if (md.slice(pos, pos + 2) === "==") return pos
    pos += 1
  }
  return -1
}

/** `=={#hex}inner==` starting at first `=` at eqStart. */
function tryCanonicalColored(md: string, eqStart: number, lineEnd: number): PreviewHighlightRegion | null {
  if (eqStart + 2 > lineEnd || md.slice(eqStart, eqStart + 2) !== "==") return null
  const tokenStart = eqStart + 2
  const tail = md.slice(tokenStart)
  const m = COLOR_TOKEN_PREFIX.exec(tail)
  if (!m || m.index !== 0) return null
  const tokenEnd = tokenStart + m[0].length
  const innerStart = tokenEnd
  const close = findClosingDoubleEquals(md, innerStart, lineEnd)
  if (close < 0) return null
  return {
    syntaxStart: eqStart,
    syntaxEnd: close + 2,
    innerStart,
    innerEnd: close,
    hexDigits: m[1].toLowerCase(),
  }
}

/** `{#hex}==inner==` starting at `{`. */
function tryLegacyColored(md: string, braceStart: number, lineEnd: number): PreviewHighlightRegion | null {
  const tail = md.slice(braceStart)
  const m = COLOR_TOKEN_PREFIX.exec(tail)
  if (!m || m.index !== 0) return null
  const tokenEnd = braceStart + m[0].length
  if (tokenEnd + 2 > lineEnd || md.slice(tokenEnd, tokenEnd + 2) !== "==") return null
  const innerStart = tokenEnd + 2
  const close = findClosingDoubleEquals(md, innerStart, lineEnd)
  if (close < 0) return null
  return {
    syntaxStart: braceStart,
    syntaxEnd: close + 2,
    innerStart,
    innerEnd: close,
    hexDigits: m[1].toLowerCase(),
  }
}

/** Plain `==inner==` at eqStart. */
function tryPlainHighlight(md: string, eqStart: number, lineEnd: number): PreviewHighlightRegion | null {
  if (eqStart + 2 > lineEnd || md.slice(eqStart, eqStart + 2) !== "==") return null
  const innerStart = eqStart + 2
  const close = findClosingDoubleEquals(md, innerStart, lineEnd)
  if (close < 0 || close === innerStart) return null
  return {
    syntaxStart: eqStart,
    syntaxEnd: close + 2,
    innerStart,
    innerEnd: close,
    hexDigits: null,
  }
}

function matchHighlightAt(md: string, abs: number, lineEnd: number): PreviewHighlightRegion | null {
  const canon = tryCanonicalColored(md, abs, lineEnd)
  if (canon) return canon
  if (md.charCodeAt(abs) === 123 /* { */) {
    const leg = tryLegacyColored(md, abs, lineEnd)
    if (leg) return leg
  }
  return tryPlainHighlight(md, abs, lineEnd)
}

function collectHighlightRegions(md: string): PreviewHighlightRegion[] {
  const regions: PreviewHighlightRegion[] = []
  let i = 0
  let inFence = false

  while (i < md.length) {
    const nl = md.indexOf("\n", i)
    const lineEnd = nl === -1 ? md.length : nl
    const lineStart = i

    const trimmed = md.slice(lineStart, lineEnd).trimStart()
    if (trimmed.startsWith("```")) {
      inFence = !inFence
      i = lineEnd === md.length ? md.length : lineEnd + 1
      continue
    }

    if (!inFence) {
      let abs = lineStart
      while (abs < lineEnd) {
        const hit = matchHighlightAt(md, abs, lineEnd)
        if (hit) {
          regions.push(hit)
          abs = hit.syntaxEnd
        } else {
          abs += 1
        }
      }
    }

    i = lineEnd === md.length ? md.length : lineEnd + 1
  }

  return regions
}

function collectTaskRegions(md: string): PreviewTaskToggleRegion[] {
  const regions: PreviewTaskToggleRegion[] = []
  let i = 0
  let inFence = false

  while (i < md.length) {
    const nl = md.indexOf("\n", i)
    const lineEnd = nl === -1 ? md.length : nl
    const line = md.slice(i, lineEnd)

    const trimmed = line.trimStart()
    if (trimmed.startsWith("```")) {
      inFence = !inFence
      i = lineEnd === md.length ? md.length : lineEnd + 1
      continue
    }

    if (!inFence) {
      const taskLine = /^(\s*)(?:[-*+])\s+\[([ xX])\]\s/.exec(line)
      if (taskLine) {
        const bracketRel = line.indexOf("[")
        if (bracketRel >= 0) regions.push({ bracketOpen: i + bracketRel })
      }
    }

    i = lineEnd === md.length ? md.length : lineEnd + 1
  }

  return regions
}

function injectHighlightMarks(source: string, regions: PreviewHighlightRegion[]): string {
  const sorted = [...regions].sort((a, b) => a.syntaxStart - b.syntaxStart)
  let out = ""
  let cursor = 0
  for (const r of sorted) {
    out += source.slice(cursor, r.syntaxStart)
    const innerText = source.slice(r.innerStart, r.innerEnd)
    const bg = rgbaBackground(r.hexDigits, YABA_HIGHLIGHT_BACKGROUND_ALPHA)
    const hexAttr = r.hexDigits ?? ""
    out += `<mark class="yaba-preview-highlight-mark" role="button" tabindex="0" data-yaba-syntax-start="${r.syntaxStart}" data-yaba-syntax-end="${r.syntaxEnd}" data-yaba-inner-start="${r.innerStart}" data-yaba-inner-end="${r.innerEnd}" data-yaba-hex="${hexAttr}" style="background-color: ${bg}; border-radius: 0.2em; box-decoration-break: clone; -webkit-box-decoration-break: clone">${escapeHighlightInner(innerText)}</mark>`
    cursor = r.syntaxEnd
  }
  out += source.slice(cursor)
  return out
}

export function prepareMarkdownForPreview(source: string): {
  markdown: string
  taskRegions: PreviewTaskToggleRegion[]
} {
  const trimmed = source ?? ""
  const highlights = collectHighlightRegions(trimmed)
  const taskRegions = collectTaskRegions(trimmed)
  const markdown = injectHighlightMarks(trimmed, highlights)
  return { markdown, taskRegions }
}
