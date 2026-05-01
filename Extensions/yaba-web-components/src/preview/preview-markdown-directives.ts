/**
 * Convert readable annotation directives to HTML spans before react-markdown renders.
 *
 * Syntax:
 *   ::yaba-annotation{id="<id>" color="YELLOW"}inner text::
 *
 * Inner text is treated as plain text (escaped); Markdown inside annotations is not parsed.
 */

const HIGHLIGHT_BY_ROLE: Record<string, string> = {
  NONE: "yaba-highlight-yellow",
  BLUE: "yaba-highlight-blue",
  BROWN: "yaba-highlight-brown",
  CYAN: "yaba-highlight-cyan",
  GRAY: "yaba-highlight-gray",
  GREEN: "yaba-highlight-green",
  INDIGO: "yaba-highlight-indigo",
  MINT: "yaba-highlight-mint",
  ORANGE: "yaba-highlight-orange",
  PINK: "yaba-highlight-pink",
  PURPLE: "yaba-highlight-purple",
  RED: "yaba-highlight-red",
  TEAL: "yaba-highlight-teal",
  YELLOW: "yaba-highlight-yellow",
}

function highlightClass(roleRaw: string): string {
  const role = roleRaw.trim().toUpperCase()
  return HIGHLIGHT_BY_ROLE[role] ?? HIGHLIGHT_BY_ROLE.YELLOW
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
}

function escapeAttr(s: string): string {
  return s.replace(/"/g, "&quot;").replace(/</g, "&lt;")
}

const HEADER_RE = /^::yaba-annotation\{id="([^"]+)"\s+color="([^"]+)"\}$/

export function preprocessYabaAnnotationDirectives(markdown: string): string {
  const needle = "::yaba-annotation{"
  let i = 0
  let out = ""
  while (i < markdown.length) {
    const start = markdown.indexOf(needle, i)
    if (start === -1) {
      out += markdown.slice(i)
      break
    }
    out += markdown.slice(i, start)
    const hdrEnd = markdown.indexOf("}", start)
    if (hdrEnd === -1) {
      out += markdown.slice(start)
      break
    }
    const header = markdown.slice(start, hdrEnd + 1)
    const closeIdx = markdown.indexOf("::", hdrEnd + 1)
    if (closeIdx === -1) {
      out += markdown.slice(start)
      break
    }
    const inner = markdown.slice(hdrEnd + 1, closeIdx)
    const m = HEADER_RE.exec(header)
    if (!m) {
      out += markdown.slice(start, closeIdx + 2)
      i = closeIdx + 2
      continue
    }
    const id = m[1]
    const role = m[2]
    const hl = highlightClass(role)
    const span =
      `<span class="yaba-annotation-mark yaba-annotation-decoration ${hl}" ` +
      `data-yaba-annotation-id="${escapeAttr(id)}" data-annotation-id="${escapeAttr(id)}">` +
      `${escapeHtml(inner)}</span>`
    out += span
    i = closeIdx + 2
  }
  return out
}
