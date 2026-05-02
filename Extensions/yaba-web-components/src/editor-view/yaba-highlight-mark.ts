/**
 * GFM-style highlight spans: `==marked text==`.
 *
 * Highlighted via `yabaHighlightMarkTag` → `.yaba-md-mark` in `yaba-markdown-highlight-classes.ts`.
 */
import { Tag } from "@lezer/highlight"
import type { InlineContext, MarkdownExtension } from "@lezer/markdown"

/** Distinct scope for `==…==` highlight spans (this `@lezer/highlight` version has no `tags.mark`). */
export const yabaHighlightMarkTag = Tag.define()

function parityBackslashesBefore(cx: InlineContext, pos: number): number {
  let count = 0
  for (let p = pos - 1; p >= cx.offset; p--) {
    if (cx.char(p) !== 92 /* \ */) break
    count++
  }
  return count
}

function parseHighlight(cx: InlineContext, next: number, pos: number): number {
  if (next !== 61 /* = */ || cx.char(pos + 1) !== 61) return -1
  if (parityBackslashesBefore(cx, pos) % 2 === 1) return -1

  const innerStart = pos + 2
  const tail = cx.slice(innerStart, cx.end)
  const relClose = tail.indexOf("==")
  if (relClose < 0) return -1

  const closeStart = innerStart + relClose
  if (parityBackslashesBefore(cx, closeStart) % 2 === 1) return -1

  cx.addElement(cx.elt("Highlight", innerStart, closeStart))
  return closeStart + 2
}

export const yabaHighlightMark: MarkdownExtension = {
  defineNodes: [{ name: "Highlight", style: yabaHighlightMarkTag }],
  parseInline: [{ name: "Highlight", parse: parseHighlight, before: "Autolink" }],
}
