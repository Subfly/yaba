/**
 * Remark-style math in Markdown (`$…$`, `$$…$$`) with nested LaTeX highlighting via `parseMixed`.
 *
 * Mirrors the approach discussed in CodeMirror/Lezer Markdown + LaTeX:
 * ({@link https://discuss.codemirror.net/t/markdown-and-latex-syntax-highlighting/4382})
 */
import { parseMixed } from "@lezer/common"
import { Tag } from "@lezer/highlight"
import type { MarkdownExtension } from "@lezer/markdown"
import type { BlockContext, InlineContext, Line } from "@lezer/markdown"
import { latexLanguage } from "codemirror-lang-latex"

/** Distinct from subscript/superscript `special(content)` — used only for `$` math spans. */
export const yabaMathShellTag = Tag.define()
/** Delimiter tokens (`$` / `$$` fence marks). */
export const yabaMathFenceTag = Tag.define()

const latexParser = latexLanguage.parser

function parityBackslashes(text: string, beforeIndex: number): number {
  let count = 0
  for (let i = beforeIndex - 1; i >= 0 && text.charCodeAt(i) === 92; i--)
    count++
  return count
}

function findUnescapedDoubleDollar(slice: string): number {
  for (let i = 0; i + 1 < slice.length; i++) {
    if (parityBackslashes(slice, i) % 2 !== 0) continue
    if (slice.charCodeAt(i) === 36 && slice.charCodeAt(i + 1) === 36) return i
  }
  return -1
}

function findUnescapedSingleDollar(slice: string): number {
  for (let i = 0; i < slice.length; i++) {
    if (parityBackslashes(slice, i) % 2 !== 0) continue
    if (slice.charCodeAt(i) === 36) return i
  }
  return -1
}

/** Line: optional ws from `basePos`, then `$$`, then ws only to EOL. Returns `$` column or -1. */
function closingDisplayFenceColumn(text: string, basePos: number): number {
  let j = basePos
  while (j < text.length && (text.charCodeAt(j) === 32 || text.charCodeAt(j) === 9)) j++
  if (j + 1 >= text.length) return -1
  if (text.charCodeAt(j) !== 36 || text.charCodeAt(j + 1) !== 36) return -1
  let k = j + 2
  while (k < text.length && (text.charCodeAt(k) === 32 || text.charCodeAt(k) === 9)) k++
  return k === text.length ? j : -1
}

function parseDisplayMathBlock(cx: BlockContext, line: Line): boolean {
  if (line.next !== 36 /* $ */ || line.text.charCodeAt(line.pos + 1) !== 36) return false

  const openerFrom = cx.lineStart + line.pos
  const afterOpen = line.text.slice(line.pos + 2)
  const sameLineClose = findUnescapedDoubleDollar(afterOpen)

  if (sameLineClose >= 0) {
    const innerFrom = openerFrom + 2
    const closerFrom = cx.lineStart + line.pos + 2 + sameLineClose
    const outerTo = closerFrom + 2
    cx.addElement(
      cx.elt("DisplayMathBlock", openerFrom, outerTo, [
        cx.elt("MathBlockMark", openerFrom, openerFrom + 2),
        cx.elt("MathBody", innerFrom, closerFrom),
        cx.elt("MathBlockMark", closerFrom, closerFrom + 2),
      ]),
    )
    cx.nextLine()
    return true
  }

  const trimmedAfter = afterOpen.trim()
  let innerFrom: number
  if (trimmedAfter.length > 0) {
    innerFrom = openerFrom + 2
  } else {
    if (!cx.nextLine()) return false
    /** `depth` exists at runtime but is omitted from `@lezer/markdown` typings. */
    const li = line as Line & { depth: number }
    const cxi = cx as BlockContext & { stack: unknown[] }
    if (li.depth < cxi.stack.length) return false
    innerFrom = cx.lineStart + line.pos
  }

  for (;;) {
    const col = closingDisplayFenceColumn(line.text, line.pos)
    if (col >= 0) {
      const closerFrom = cx.lineStart + col
      const outerTo = closerFrom + 2
      cx.addElement(
        cx.elt("DisplayMathBlock", openerFrom, outerTo, [
          cx.elt("MathBlockMark", openerFrom, openerFrom + 2),
          cx.elt("MathBody", innerFrom, closerFrom),
          cx.elt("MathBlockMark", closerFrom, closerFrom + 2),
        ]),
      )
      cx.nextLine()
      return true
    }
    if (!cx.nextLine()) return false
    const li2 = line as Line & { depth: number }
    const cxi2 = cx as BlockContext & { stack: unknown[] }
    if (li2.depth < cxi2.stack.length) return false
  }
}

function parseInlineMath(cx: InlineContext, next: number, pos: number): number {
  if (next !== 36 /* $ */) return -1
  if (cx.char(pos + 1) === 36) return -1

  let bs = 0
  for (let p = pos - 1; p >= cx.offset; p--) {
    if (cx.char(p) !== 92) break
    bs++
  }
  if (bs % 2 === 1) return -1

  const innerStart = pos + 1
  const fst = cx.char(innerStart)
  if (fst === 32 || fst === 9 || fst === 10 || fst === -1) return -1

  const tail = cx.slice(innerStart, cx.end)
  const relClose = findUnescapedSingleDollar(tail)
  if (relClose <= 0) return -1

  const innerEndDoc = innerStart + relClose
  return cx.addElement(
    cx.elt("InlineMath", pos, innerEndDoc + 1, [
      cx.elt("MathDelimiter", pos, pos + 1),
      cx.elt("MathBody", innerStart, innerEndDoc),
      cx.elt("MathDelimiter", innerEndDoc, innerEndDoc + 1),
    ]),
  )
}

const yabaMarkdownMathDialect: MarkdownExtension = {
  defineNodes: [
    { name: "InlineMath", style: yabaMathShellTag },
    { name: "DisplayMathBlock", block: true, style: yabaMathShellTag },
    { name: "MathDelimiter", style: yabaMathFenceTag },
    { name: "MathBlockMark", style: yabaMathFenceTag },
    "MathBody",
  ],
  parseBlock: [{ name: "DisplayMathBlock", parse: parseDisplayMathBlock, before: "FencedCode" }],
  parseInline: [{ name: "InlineMath", parse: parseInlineMath, before: "Autolink" }],
}

const yabaMarkdownMathMixed: MarkdownExtension = {
  wrap: parseMixed((node) => {
    if (node.name === "MathBody") {
      return { parser: latexParser, overlay: [{ from: node.from, to: node.to }] }
    }
    return null
  }),
}

export const yabaMarkdownMathExtensions: MarkdownExtension[] = [yabaMarkdownMathDialect, yabaMarkdownMathMixed]
