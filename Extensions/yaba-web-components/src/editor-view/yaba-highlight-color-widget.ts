/**
 * Secret editor syntax: `{#rrggbb}` — rendered as a color chip in CodeMirror only.
 * Canonical: `=={#hex}highlight==` (chip inside delimiters). Legacy `{#hex}==highlight==` still supported.
 * Stripped for Markdown preview (`MarkdownPreviewBody`).
 */
import { RangeSetBuilder } from "@codemirror/state"
import {
  Decoration,
  type DecorationSet,
  EditorView,
  ViewPlugin,
  WidgetType,
  type PluginValue,
} from "@codemirror/view"

import { postToYabaNativeHost } from "@/bridge/yaba-native-host"
import { YABA_HIGHLIGHT_BACKGROUND_ALPHA } from "@/theme/yaba-accent-palette"

export const HIGHLIGHT_COLOR_MARK_SOURCE_RE = /\{\s*#([0-9a-fA-F]{6})\s*\}/g

function hexToRgb(hexWithHash: string): { r: number; g: number; b: number } | null {
  const h = hexWithHash.replace(/^#/, "").toLowerCase()
  if (!/^[0-9a-f]{6}$/.test(h)) return null
  return {
    r: Number.parseInt(h.slice(0, 2), 16),
    g: Number.parseInt(h.slice(2, 4), 16),
    b: Number.parseInt(h.slice(4, 6), 16),
  }
}

function rgbaBackground(hexWithHash: string, alpha: number): string {
  const rgb = hexToRgb(hexWithHash)
  if (!rgb) return "transparent"
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${alpha})`
}

class HighlightColorCircleWidget extends WidgetType {
  constructor(
    readonly hexWithHash: string,
    readonly tokenFrom: number,
    readonly tokenTo: number,
  ) {
    super()
  }

  override eq(other: HighlightColorCircleWidget): boolean {
    return (
      other.hexWithHash === this.hexWithHash &&
      other.tokenFrom === this.tokenFrom &&
      other.tokenTo === this.tokenTo
    )
  }

  override toDOM(): HTMLElement {
    const el = document.createElement("span")
    el.className = "yaba-cm-highlight-color-chip"
    el.setAttribute("role", "button")
    el.setAttribute("aria-label", "Highlight color")
    el.style.display = "inline-block"
    el.style.width = "13px"
    el.style.height = "13px"
    el.style.borderRadius = "50%"
    el.style.background = this.hexWithHash
    el.style.marginLeft = "4px"
    el.style.marginRight = "5px"
    el.style.verticalAlign = "middle"
    el.style.cursor = "pointer"
    el.style.boxShadow = "inset 0 0 0 1px rgba(0,0,0,0.12)"

    el.addEventListener("click", (e) => {
      e.preventDefault()
      e.stopPropagation()
      const digits = this.hexWithHash.replace(/^#/, "").toLowerCase()
      postToYabaNativeHost({
        type: "noteHighlightColorMarkTap",
        from: this.tokenFrom,
        to: this.tokenTo,
        hex: digits,
      })
    })

    return el
  }

  override ignoreEvent(): boolean {
    return false
  }
}

function findClosingDoubleEquals(doc: { sliceString: (a: number, b: number) => string; length: number }, from: number): number {
  const max = doc.length
  for (let pos = from; pos + 1 < max; pos++) {
    if (doc.sliceString(pos, pos + 2) === "==") return pos
  }
  return -1
}

/** Tint span for `{#hex}`: legacy `{#hex}==inner==` or canonical `=={#hex}inner==`. */
function tintRangeAfterColorToken(
  doc: { sliceString: (a: number, b: number) => string; length: number },
  tokenStart: number,
  tokenEnd: number,
): { tintFrom: number; tintTo: number } | null {
  // Legacy: `{#hex}==inner==`
  if (tokenEnd + 2 <= doc.length && doc.sliceString(tokenEnd, tokenEnd + 2) === "==") {
    const innerStart = tokenEnd + 2
    const close = findClosingDoubleEquals(doc, innerStart)
    if (close < 0) return null
    return { tintFrom: innerStart, tintTo: close }
  }
  // Canonical: `=={#hex}inner==`
  if (tokenStart >= 2 && doc.sliceString(tokenStart - 2, tokenStart) === "==") {
    const innerStart = tokenEnd
    const close = findClosingDoubleEquals(doc, innerStart)
    if (close < 0) return null
    return { tintFrom: innerStart, tintTo: close }
  }
  return null
}

/** Builds `Decoration.mark` ranges tinting highlight text (excluding the `{#hex}` token). */
function coloredHighlightDecorations(view: EditorView): DecorationSet {
  const builder = new RangeSetBuilder<Decoration>()
  const doc = view.state.doc

  for (const { from: rFrom, to: rTo } of view.visibleRanges) {
    const text = doc.sliceString(rFrom, rTo)
    HIGHLIGHT_COLOR_MARK_SOURCE_RE.lastIndex = 0
    let m: RegExpExecArray | null
    while ((m = HIGHLIGHT_COLOR_MARK_SOURCE_RE.exec(text))) {
      const markStart = rFrom + m.index
      const markEnd = markStart + m[0].length
      const hexDigits = m[1].toLowerCase()
      const hexWithHash = `#${hexDigits}`

      const span = tintRangeAfterColorToken(doc, markStart, markEnd)
      if (!span) continue

      const bg = rgbaBackground(hexWithHash, YABA_HIGHLIGHT_BACKGROUND_ALPHA)
      const deco = Decoration.mark({
        class: "yaba-md-colored-highlight",
        attributes: {
          style: `background-color: ${bg} !important; border-radius: 0.2em; box-decoration-break: clone; -webkit-box-decoration-break: clone`,
        },
      })
      builder.add(span.tintFrom, span.tintTo, deco)
    }
  }

  return builder.finish()
}

function colorChipDecorations(view: EditorView): DecorationSet {
  const chips = []
  for (const { from: rFrom, to: rTo } of view.visibleRanges) {
    const text = view.state.doc.sliceString(rFrom, rTo)
    HIGHLIGHT_COLOR_MARK_SOURCE_RE.lastIndex = 0
    let m: RegExpExecArray | null
    while ((m = HIGHLIGHT_COLOR_MARK_SOURCE_RE.exec(text))) {
      const start = rFrom + m.index
      const end = start + m[0].length
      if (!tintRangeAfterColorToken(view.state.doc, start, end)) continue
      const hexDigits = m[1].toLowerCase()
      const hexWithHash = `#${hexDigits}`
      chips.push(
        Decoration.replace({
          widget: new HighlightColorCircleWidget(hexWithHash, start, end),
          inclusive: false,
        }).range(start, end),
      )
    }
  }
  return Decoration.set(chips)
}

class ColorChipPlugin implements PluginValue {
  decorations: DecorationSet

  constructor(view: EditorView) {
    this.decorations = colorChipDecorations(view)
  }

  update(update: { docChanged: boolean; viewportChanged: boolean; view: EditorView }): void {
    if (update.docChanged || update.viewportChanged) {
      this.decorations = colorChipDecorations(update.view)
    }
  }
}

class ColoredHighlightPlugin implements PluginValue {
  decorations: DecorationSet

  constructor(view: EditorView) {
    this.decorations = coloredHighlightDecorations(view)
  }

  update(update: { docChanged: boolean; viewportChanged: boolean; view: EditorView }): void {
    if (update.docChanged || update.viewportChanged) {
      this.decorations = coloredHighlightDecorations(update.view)
    }
  }
}

/** Widget chips + tinted spans for `{#hex}` inside or before `==…==`. */
export function yabaHighlightColorMarkExtensions(): import("@codemirror/state").Extension[] {
  return [
    ViewPlugin.fromClass(ColorChipPlugin, { decorations: (v) => v.decorations }),
    ViewPlugin.fromClass(ColoredHighlightPlugin, { decorations: (v) => v.decorations }),
  ]
}
