import type { EditorFormattingState } from "../editor-formatting"

export type YabaNativeHostFeature = "editor" | "preview" | "note"

/** Single envelope for all web -> native host events. */
export type YabaNativeHostPayload =
  | { type: "bridgeReady"; feature: YabaNativeHostFeature }
  | { type: "shellLoad"; result: "loaded" | "error" }
  | { type: "noteAutosaveIdle" }
  | {
      type: "readerMetrics"
      currentPage: number
      pageCount: number
      /** Rich-text editor toolbar state; omitted in PDF/readable viewer. */
      formatting?: EditorFormattingState
    }
  | { type: "mathTap"; kind: "inline" | "block"; pos: number; latex: string }
  | {
      type: "inlineLinkTap"
      pos: number
      text: string
      url: string
    }
  /** Editor `{#rrggbb}` color chip tapped — Darwin opens `YabaColorPicker` and calls `replaceHighlightColorMark`. */
  | {
      type: "noteHighlightColorMarkTap"
      from: number
      to: number
      /** Six lowercase hex digits, no `#`. */
      hex: string
    }
  /** Preview `<mark>` tap — native replaces highlight syntax slice after picker (UTF-16 offsets like JS). */
  | {
      type: "previewHighlightMarkTap"
      syntaxStart: number
      syntaxEnd: number
      innerStart: number
      innerEnd: number
      /** Current palette hex, or empty when plain `==…==`. */
      hex: string
    }
  /** Preview task checkbox tap — toggles `[ ]` / `[x]` at `bracketOpen` (`[` index). */
  | {
      type: "previewTaskCheckboxTap"
      bracketOpen: number
    }
  | {
      type: "inlineMentionTap"
      pos: number
      text: string
      bookmarkId: string
      bookmarkKindCode: number
      bookmarkLabel: string
    }
  | {
      type: "converterJob"
      jobId: string
      kind: "pdf"
      status: "pending" | "done" | "error"
      outputJson?: string
      error?: string
    }
  /**
   * Mac Catalyst only (`window.__YABA_MAC_CATALYST__`): CodeMirror + WKWebView clipboard bridge.
   * Compose / iOS / Android hosts should ignore unknown `type` values without failing.
   */
  | { type: "catalystClipboard"; op: "write"; text: string }
  | { type: "catalystClipboard"; op: "readPaste" }
