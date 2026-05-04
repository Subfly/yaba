/**
 * Native `YabaEditorBridge.dispatch` — Markdown source transforms for CodeMirror;
 * parity with Android `YabaEditorCommands` / Darwin `YabaEditorDispatchPayload`.
 */
import { indentLess, indentMore, redo, undo } from "@codemirror/commands"
import { EditorSelection, type EditorState } from "@codemirror/state"
import type { EditorView } from "@codemirror/view"
import type { EditorCommandPayload } from "./editor-commands"
import { YABA_DEFAULT_HIGHLIGHT_HEX_DIGITS } from "@/theme/yaba-accent-palette"

function escapeMarkdownLinkText(value: string): string {
  return value
    .replaceAll("\\", "\\\\")
    .replaceAll("[", "\\[")
    .replaceAll("]", "\\]")
    .replaceAll("\r", "")
    .replaceAll("\n", " ")
}

function escapeMarkdownLinkUrl(value: string): string {
  return value
    .replaceAll("\\", "\\\\")
    .replaceAll("<", "\\<")
    .replaceAll(">", "\\>")
}

function shouldWrapLinkUrlInAngleBrackets(url: string): boolean {
  return /\s/.test(url) || /[()]/.test(url) || /[<>]/.test(url)
}

function buildMarkdownLink(text: string, url: string): string {
  const escapedText = escapeMarkdownLinkText(text)
  const escapedUrl = escapeMarkdownLinkUrl(url)
  if (shouldWrapLinkUrlInAngleBrackets(url)) {
    return `[${escapedText}](<${escapedUrl}>)`
  }
  return `[${escapedText}](${escapedUrl})`
}

function buildMarkdownImage(alt: string, url: string): string {
  const escapedAlt = escapeMarkdownLinkText(alt)
  const escapedUrl = escapeMarkdownLinkUrl(url)
  if (shouldWrapLinkUrlInAngleBrackets(url)) {
    return `![${escapedAlt}](<${escapedUrl}>)`
  }
  return `![${escapedAlt}](${escapedUrl})`
}

/** GFM pipe table: header row + delimiter + body rows (`rows` = total cell lines including header). */
function buildGfmTableMarkdown(rows: number, cols: number, _withHeaderRow: boolean): string {
  const r = Math.max(1, Math.min(20, Math.floor(rows)))
  const c = Math.max(1, Math.min(20, Math.floor(cols)))
  const dataRow = (): string => "| " + Array.from({ length: c }, () => " ").join(" | ") + " |"
  const sepRow = "| " + Array.from({ length: c }, () => "---").join(" | ") + " |"
  const lines: string[] = [dataRow(), sepRow]
  for (let i = 1; i < r; i++) {
    lines.push(dataRow())
  }
  return "\n" + lines.join("\n") + "\n"
}

function toggleAroundSymmetric(view: EditorView, mark: string): void {
  const open = mark
  const close = mark
  const { state } = view
  const main = state.selection.main
  const from = main.from
  const to = main.to
  const doc = state.doc

  const canUnwrap =
    from >= open.length &&
    to + close.length <= doc.length &&
    doc.sliceString(from - open.length, from) === open &&
    doc.sliceString(to, to + close.length) === close

  if (canUnwrap) {
    view.dispatch({
      changes: [
        { from: to, to: to + close.length, insert: "" },
        { from: from - open.length, to: from, insert: "" },
      ],
      selection: EditorSelection.range(from - open.length, to - open.length),
    })
    return
  }

  if (from === to) {
    const insert = `${open}${close}`
    view.dispatch({
      changes: { from, insert },
      selection: EditorSelection.cursor(from + open.length),
    })
    return
  }

  const inner = doc.sliceString(from, to)
  view.dispatch({
    changes: { from, to, insert: `${open}${inner}${close}` },
    selection: EditorSelection.range(from + open.length, to + open.length),
  })
}

const HIGHLIGHT_EQ = "=="

/** `{#rrggbb}` embedded in `==…==` when inserting highlights from the toolbar (canonical `=={#hex}…==`). */
function defaultHighlightColorToken(): string {
  return `{#${YABA_DEFAULT_HIGHLIGHT_HEX_DIGITS}}`
}

/** `{#rrggbb}` immediately before this opening `==` (legacy `{#hex}==…==`). */
function trailingHighlightColorTokenStart(doc: EditorView["state"]["doc"], openEqStart: number): number | null {
  const scanStart = Math.max(0, openEqStart - 28)
  const prefix = doc.sliceString(scanStart, openEqStart)
  const m = /\{\s*#[0-9a-fA-F]{6}\s*\}$/.exec(prefix)
  if (!m) return null
  return scanStart + m.index
}

type HighlightUnwrap =
  | { mode: "inside"; openEqStart: number; tokenStart: number; innerFrom: number }
  | { mode: "legacy"; openEqStart: number; tokenStart: number; innerFrom: number }
  | { mode: "plain"; openEqStart: number; innerFrom: number }

function resolveHighlightUnwrap(
  doc: EditorView["state"]["doc"],
  innerFrom: number,
  innerTo: number,
): HighlightUnwrap | null {
  if (innerTo + 2 > doc.length || doc.sliceString(innerTo, innerTo + 2) !== "==") return null

  const scanStart = Math.max(0, innerFrom - 28)
  const beforeInner = doc.sliceString(scanStart, innerFrom)
  const insideTok = /\{\s*#[0-9a-fA-F]{6}\s*\}$/.exec(beforeInner)
  if (insideTok) {
    const tokenStart = scanStart + insideTok.index
    if (tokenStart >= 2 && doc.sliceString(tokenStart - 2, tokenStart) === "==") {
      return {
        mode: "inside",
        openEqStart: tokenStart - 2,
        tokenStart,
        innerFrom,
      }
    }
  }

  if (innerFrom >= 2 && doc.sliceString(innerFrom - 2, innerFrom) === "==") {
    const openEqStart = innerFrom - 2
    const tokenStart = trailingHighlightColorTokenStart(doc, openEqStart)
    if (tokenStart != null) {
      return { mode: "legacy", openEqStart, tokenStart, innerFrom }
    }
    return { mode: "plain", openEqStart, innerFrom }
  }

  return null
}

function toggleHighlight(view: EditorView): void {
  const open = HIGHLIGHT_EQ
  const close = HIGHLIGHT_EQ
  const token = defaultHighlightColorToken()
  const { state } = view
  const main = state.selection.main
  const from = main.from
  const to = main.to
  const doc = state.doc

  const unwrap = resolveHighlightUnwrap(doc, from, to)
  if (unwrap) {
    const innerLen = to - from
    if (unwrap.mode === "inside") {
      view.dispatch({
        changes: [
          { from: to, to: to + 2, insert: "" },
          { from: unwrap.openEqStart, to: unwrap.openEqStart + 2, insert: "" },
          { from: unwrap.tokenStart, to: unwrap.innerFrom, insert: "" },
        ],
        selection: EditorSelection.range(unwrap.openEqStart, unwrap.openEqStart + innerLen),
      })
    } else if (unwrap.mode === "legacy") {
      view.dispatch({
        changes: [
          { from: to, to: to + 2, insert: "" },
          { from: unwrap.openEqStart, to: unwrap.innerFrom, insert: "" },
          { from: unwrap.tokenStart, to: unwrap.openEqStart, insert: "" },
        ],
        selection: EditorSelection.range(unwrap.tokenStart, unwrap.tokenStart + innerLen),
      })
    } else {
      view.dispatch({
        changes: [
          { from: to, to: to + 2, insert: "" },
          { from: unwrap.openEqStart, to: unwrap.innerFrom, insert: "" },
        ],
        selection: EditorSelection.range(unwrap.openEqStart, unwrap.openEqStart + innerLen),
      })
    }
    return
  }

  if (from === to) {
    const insert = `${open}${token}${close}`
    view.dispatch({
      changes: { from, insert },
      selection: EditorSelection.cursor(from + open.length + token.length),
    })
    return
  }

  const inner = doc.sliceString(from, to)
  view.dispatch({
    changes: { from, to, insert: `${open}${token}${inner}${close}` },
    selection: EditorSelection.range(from + open.length + token.length, from + open.length + token.length + inner.length),
  })
}

function toggleItalicAsterisk(view: EditorView): void {
  const { state } = view
  const main = state.selection.main
  const from = main.from
  const to = main.to
  const doc = state.doc
  const text = doc.toString()
  const openSingle =
    from >= 1 &&
    text.charCodeAt(from - 1) === 42 /* * */ &&
    (from < 2 || text.charCodeAt(from - 2) !== 42)
  const closeSingle =
    to < text.length &&
    text.charCodeAt(to) === 42 &&
    (to + 1 >= text.length || text.charCodeAt(to + 1) !== 42)

  if (openSingle && closeSingle) {
    view.dispatch({
      changes: [
        { from: to, to: to + 1, insert: "" },
        { from: from - 1, to: from, insert: "" },
      ],
      selection: EditorSelection.range(from - 1, to - 1),
    })
    return
  }

  if (from === to) {
    view.dispatch({
      changes: { from, insert: "**" },
      selection: EditorSelection.cursor(from + 1),
    })
    return
  }

  const inner = doc.sliceString(from, to)
  view.dispatch({
    changes: { from, to, insert: `*${inner}*` },
    selection: EditorSelection.range(from + 1, to + 1),
  })
}

function tickRunLengthFor(text: string, minLen: number): number {
  let n = minLen
  for (;;) {
    const fence = "`".repeat(n)
    if (!text.includes(fence)) return n
    n += 1
  }
}

function toggleInlineCode(view: EditorView): void {
  const { state } = view
  const main = state.selection.main
  const from = main.from
  const to = main.to
  const doc = state.doc
  const innerSel = from === to ? "" : doc.sliceString(from, to)

  for (const n of [1, 2, 3] as const) {
    const fence = "`".repeat(n)
    const pad = n > 1 ? " " : ""
    if (
      from >= n &&
      to + n <= doc.length &&
      doc.sliceString(from - n, from) === fence &&
      doc.sliceString(to, to + n) === fence
    ) {
      const innerRaw = doc.sliceString(from, to)
      const unwrapped =
        n > 1 && innerRaw.startsWith(pad) && innerRaw.endsWith(pad)
          ? innerRaw.slice(pad.length, innerRaw.length - pad.length)
          : innerRaw
      view.dispatch({
        changes: { from: from - n, to: to + n, insert: unwrapped },
        selection: EditorSelection.range(from - n, from - n + unwrapped.length),
      })
      return
    }
  }

  const run = tickRunLengthFor(innerSel, 1)
  const fence = "`".repeat(run)
  const pad = run > 1 ? " " : ""
  const insertBody = `${pad}${innerSel}${pad}`
  if (from === to) {
    view.dispatch({
      changes: { from, insert: `${fence}${fence}` },
      selection: EditorSelection.cursor(from + run),
    })
    return
  }
  view.dispatch({
    changes: { from, to, insert: `${fence}${insertBody}${fence}` },
    selection: EditorSelection.range(
      from + run + pad.length,
      from + run + pad.length + innerSel.length,
    ),
  })
}

function lineCharRangeForSelection(state: EditorState, from: number, to: number): { start: number; end: number } {
  const startL = state.doc.lineAt(from).number
  const endL = state.doc.lineAt(Math.max(from, Math.min(to, state.doc.length))).number
  return {
    start: state.doc.line(startL).from,
    end: state.doc.line(endL).to,
  }
}

function toggleLinePrefix(
  view: EditorView,
  match: RegExp,
  add: (lineText: string) => string,
  strip: (lineText: string) => string | null,
): void {
  const { state } = view
  const main = state.selection.main
  const { start, end } = lineCharRangeForSelection(state, main.from, main.to)
  const lines: { from: number; text: string }[] = []
  for (let n = state.doc.lineAt(start).number; n <= state.doc.lineAt(end).number; n++) {
    const ln = state.doc.line(n)
    lines.push({ from: ln.from, text: ln.text })
  }
  const allMatch = lines.length > 0 && lines.every((l) => match.test(l.text))
  const changes = lines.map((l) => {
    if (allMatch) {
      const next = strip(l.text)
      return { from: l.from, to: l.from + l.text.length, insert: next ?? l.text }
    }
    return { from: l.from, to: l.from + l.text.length, insert: add(l.text) }
  })
  view.dispatch({ changes })
}

function toggleBlockquote(view: EditorView): void {
  toggleLinePrefix(
    view,
    /^\s*>\s?/,
    (text) => {
      const m = text.match(/^(\s*)/)
      const indent = m?.[1] ?? ""
      const rest = text.slice(indent.length)
      return rest.startsWith(">") ? text : `${indent}> ${rest}`
    },
    (text) => {
      const m = text.match(/^(\s*)> ?/)
      if (!m) return null
      return m[1] + text.slice(m[0].length)
    },
  )
}

const looseBulletItemRe = /^\s*[-*]\s+(?:\[[ xX]\]\s+)?/

function toggleBulletList(view: EditorView): void {
  toggleLinePrefix(
    view,
    looseBulletItemRe,
    (text) => {
      const m = text.match(/^(\s*)/)
      const indent = m?.[1] ?? ""
      const rest = text.slice(indent.length)
      if (looseBulletItemRe.test(text)) return text
      return `${indent}- ${rest}`
    },
    (text) => {
      if (!looseBulletItemRe.test(text)) return null
      return text.replace(looseBulletItemRe, "")
    },
  )
}

const orderedItemRe = /^\s*\d+\.\s+/

function toggleOrderedList(view: EditorView): void {
  toggleLinePrefix(
    view,
    orderedItemRe,
    (text) => {
      const m = text.match(/^(\s*)/)
      const indent = m?.[1] ?? ""
      const rest = text.slice(indent.length)
      if (orderedItemRe.test(text)) return text
      return `${indent}1. ${rest}`
    },
    (text) => {
      if (!orderedItemRe.test(text)) return null
      return text.replace(orderedItemRe, "")
    },
  )
}

const taskItemRe = /^\s*[-*]\s+\[[ xX]\]\s+/

function toggleTaskList(view: EditorView): void {
  toggleLinePrefix(
    view,
    taskItemRe,
    (text) => {
      const m = text.match(/^(\s*)/)
      const indent = m?.[1] ?? ""
      const rest = text.slice(indent.length)
      if (taskItemRe.test(text)) return text
      const plainBullet = /^\s*[-*]\s+/
      if (plainBullet.test(text)) {
        return text.replace(/^\s*[-*]\s+/, `${indent}- [ ] `)
      }
      return `${indent}- [ ] ${rest}`
    },
    (text) => {
      if (!taskItemRe.test(text)) return null
      return text.replace(taskItemRe, "")
    },
  )
}

function insertHorizontalRule(view: EditorView): void {
  const { state } = view
  const main = state.selection.main
  const from = main.from
  const insert = from === 0 ? "---\n" : "\n\n---\n\n"
  view.dispatch({
    changes: { from, insert },
    selection: EditorSelection.cursor(from + insert.length),
  })
}

function setHeadingLevel(view: EditorView, level: number): void {
  const lv = Math.min(6, Math.max(1, Math.round(level)))
  const hashes = "#".repeat(lv)
  const { state } = view
  const main = state.selection.main
  const { start, end } = lineCharRangeForSelection(state, main.from, main.to)
  const lines: { from: number; text: string }[] = []
  for (let n = state.doc.lineAt(start).number; n <= state.doc.lineAt(end).number; n++) {
    const ln = state.doc.line(n)
    lines.push({ from: ln.from, text: ln.text })
  }
  const changes = lines.map((l) => {
    const m = l.text.match(/^(\s*)/)
    const ws = m?.[1] ?? ""
    const body = l.text.slice(ws.length).replace(/^#{1,6}\s+/, "")
    return { from: l.from, to: l.from + l.text.length, insert: `${ws}${hashes} ${body}` }
  })
  view.dispatch({ changes })
}

function toggleCodeBlockFence(view: EditorView): void {
  const { state } = view
  const main = state.selection.main
  const { start, end } = lineCharRangeForSelection(state, main.from, main.to)
  const first = state.doc.lineAt(start)
  const last = state.doc.lineAt(end)
  const openFence = /^\s*```\w*\s*$/
  const closeFence = /^\s*```\s*$/

  if (openFence.test(first.text) && last.number > first.number && closeFence.test(last.text)) {
    const innerStartN = first.number + 1
    const innerEndN = last.number - 1
    let insert = ""
    if (innerEndN >= innerStartN) {
      const a = state.doc.line(innerStartN).from
      const b = state.doc.line(innerEndN).to
      insert = state.doc.sliceString(a, b)
    }
    let toDel = last.to
    if (toDel < state.doc.length && state.doc.sliceString(toDel, toDel + 1) === "\n") toDel += 1
    view.dispatch({
      changes: { from: first.from, to: toDel, insert },
      selection: EditorSelection.cursor(first.from + insert.length),
    })
    return
  }

  const inner = state.doc.sliceString(start, end)
  const body = inner.length ? `${inner}\n` : "\n"
  const wrapped = `\`\`\`\n${body}\`\`\``
  view.dispatch({
    changes: { from: start, to: end, insert: wrapped },
    selection: EditorSelection.cursor(start + 4),
  })
}

function insertMath(view: EditorView, mode: "inline" | "block", latex: string): void {
  const { state } = view
  const from = state.selection.main.from
  if (mode === "inline") {
    if (latex.length) {
      const wrap = `$${latex}$`
      view.dispatch({
        changes: { from, insert: wrap },
        selection: EditorSelection.cursor(from + wrap.length),
      })
    } else {
      view.dispatch({
        changes: { from, insert: "$$" },
        selection: EditorSelection.cursor(from + 1),
      })
    }
    return
  }
  const trimmed = latex.trim()
  if (trimmed.length > 0) {
    const fence = `\n$$\n${trimmed}\n$$\n`
    view.dispatch({
      changes: { from, insert: fence },
      selection: EditorSelection.cursor(from + 4 + trimmed.length),
    })
  } else {
    const fence = "\n$$\n\n$$\n"
    view.dispatch({
      changes: { from, insert: fence },
      selection: EditorSelection.cursor(from + 4),
    })
  }
}

/** Apply native editor command; no-op if view is missing. */
export function dispatchEditorNativeCommand(view: EditorView | null, payload: EditorCommandPayload): void {
  if (!view) return
  const kind = payload.type

  switch (kind) {
    case "toggleBold":
      toggleAroundSymmetric(view, "**")
      break
    case "toggleItalic":
      toggleItalicAsterisk(view)
      break
    case "toggleHighlight":
      toggleHighlight(view)
      break
    case "toggleStrikethrough":
      toggleAroundSymmetric(view, "~~")
      break
    case "toggleCode":
      toggleInlineCode(view)
      break
    case "toggleCodeBlock":
      toggleCodeBlockFence(view)
      break
    case "toggleQuote":
      toggleBlockquote(view)
      break
    case "insertHr":
      insertHorizontalRule(view)
      break
    case "insertLink": {
      const text = typeof payload.text === "string" ? payload.text : ""
      const url = typeof payload.url === "string" ? payload.url : ""
      const linkText = text.trim()
      const linkUrl = url.trim()
      const isImage = payload.image === true
      const inserted = isImage ? buildMarkdownImage(linkText, linkUrl) : buildMarkdownLink(linkText, linkUrl)
      const { state } = view
      const main = state.selection.main
      const from = main.from
      const to = main.to
      view.dispatch({
        changes: { from, to, insert: inserted },
        selection: EditorSelection.cursor(from + inserted.length),
      })
      break
    }
    case "insertTable": {
      const rowN = typeof payload.rows === "number" ? payload.rows : 3
      const colN = typeof payload.cols === "number" ? payload.cols : 3
      const withHeaderRow = payload.withHeaderRow === true
      const inserted = buildGfmTableMarkdown(rowN, colN, withHeaderRow)
      const { state } = view
      const main = state.selection.main
      const from = main.from
      const to = main.to
      view.dispatch({
        changes: { from, to, insert: inserted },
        selection: EditorSelection.cursor(from + inserted.length),
      })
      break
    }
    case "toggleBulletedList":
      toggleBulletList(view)
      break
    case "toggleNumberedList":
      toggleOrderedList(view)
      break
    case "toggleTaskList":
      toggleTaskList(view)
      break
    case "indent":
      indentMore(view)
      break
    case "outdent":
      indentLess(view)
      break
    case "undo":
      undo(view)
      break
    case "redo":
      redo(view)
      break
    case "setHeading": {
      const lv = typeof payload.level === "number" ? payload.level : 1
      setHeadingLevel(view, lv)
      break
    }
    case "insertInlineMath": {
      const tex = typeof payload.latex === "string" ? payload.latex : ""
      insertMath(view, "inline", tex)
      break
    }
    case "insertBlockMath": {
      const tex = typeof payload.latex === "string" ? payload.latex : ""
      insertMath(view, "block", tex)
      break
    }
    default:
      break
  }

  view.focus()
}
