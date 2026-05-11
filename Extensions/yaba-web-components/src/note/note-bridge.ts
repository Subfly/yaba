/**
 * Unified notemark shell: one document with CodeMirror + react-markdown preview.
 * Exposes `window.YabaNoteBridge` (Darwin) — supersedes dual `YabaEditorBridge`/`YabaPreviewBridge` on this page.
 */
import type { ViewUpdate } from "@codemirror/view"
import type { EditorSurface } from "@/editor-view/surface"
import { initEditorBridge, type YabaEditorBridge } from "@/bridge/editor-bridge"
import type { Platform, AppearanceMode } from "@/theme/url-params"
import type { ReaderPreferences } from "@/bridge/reader-preferences"
import type { EditorCommandPayload } from "@/bridge/editor-commands"
import {
  applyReaderColumnLayoutToDocument,
  type ReaderColumnLayoutPayload,
} from "@/preview/preview-bridge"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"

export type YabaNoteSurfaceMode = "editor" | "preview" | "split"

export interface YabaNoteBridge {
  isReady: () => boolean
  getSelectionSnapshot: YabaEditorBridge["getSelectionSnapshot"]
  getSelectedText: YabaEditorBridge["getSelectedText"]
  setPlatform: (platform: Platform) => void
  setAppearance: (mode: AppearanceMode) => void
  setCursorColor: (color: string) => void
  setWebChromeInsets: (topChromeInsetPx: number) => void
  setReaderColumnLayout: (layout: ReaderColumnLayoutPayload) => void
  setReaderPreferences: (preferences: Partial<ReaderPreferences>) => void
  setEditable: YabaEditorBridge["setEditable"]
  setPlaceholder: YabaEditorBridge["setPlaceholder"]
  setMarkdown: (markdown: string, options?: { assetsBaseUrl?: string }) => void
  getMarkdown: () => string
  getUsedInlineAssetSrcs: () => string
  getActiveFormatting: () => string
  focus: YabaEditorBridge["focus"]
  unFocus: YabaEditorBridge["unFocus"]
  exportMarkdown: () => string
  /** No-op stub — scroll sync disabled (native callers may still exist). */
  getSyncedScrollFraction: () => string
  /** No-op stub — scroll sync disabled (native callers may still exist). */
  setSyncedScrollFraction: (_t: number) => void
  dispatch: (payload: EditorCommandPayload) => void
  replaceHighlightColorMark: YabaEditorBridge["replaceHighlightColorMark"]
  /** Matches Darwin link preview checkbox toggle (UTF-16 indices). */
  togglePreviewTaskCheckbox: (bracketOpen: number) => void
  /** After native color picker for preview highlight tap. */
  replacePreviewHighlightSyntax: (
    syntaxStart: number,
    syntaxEnd: number,
    innerStart: number,
    innerEnd: number,
    hexDigitsNoHash: string,
  ) => void
  setSurfaceMode: (mode: YabaNoteSurfaceMode) => void
}

function wrapSetMarkdownToSyncPreview(
  ed: YabaEditorBridge,
  setPreviewMarkdown: (s: string) => void,
): void {
  const orig = ed.setMarkdown.bind(ed)
  ed.setMarkdown = (markdown: string, options?: { assetsBaseUrl?: string }) => {
    orig(markdown, options)
    queueMicrotask(() => {
      setPreviewMarkdown(ed.getMarkdown())
    })
  }
}

function toggleTaskCheckboxInMarkdown(md: string, bracketOpen: number): string {
  const len = md.length
  if (bracketOpen < 0 || bracketOpen + 2 >= len) return md
  const innerIdx = bracketOpen + 1
  const ch = md[innerIdx] ?? ""
  const newCh = ch.toLowerCase() === "x" ? " " : "x"
  return md.slice(0, innerIdx) + newCh + md.slice(innerIdx + 1)
}

function replaceHighlightSlice(
  md: string,
  syntaxStart: number,
  syntaxEnd: number,
  innerStart: number,
  innerEnd: number,
  hexDigitsNoHash: string,
): string {
  const inner = md.slice(innerStart, innerEnd)
  const replacement = `=={#${hexDigitsNoHash}}${inner}==`
  return md.slice(0, syntaxStart) + replacement + md.slice(syntaxEnd)
}

export interface InitNoteBridgeOptions {
  /** Push rendered preview markdown when editor source changes. */
  setPreviewMarkdown: (markdown: string) => void
}

export function initNoteBridge(
  surface: EditorSurface,
  viewActivityRef: { current: ((u: ViewUpdate) => void) | null },
  opts: InitNoteBridgeOptions,
): void {
  initEditorBridge(surface, viewActivityRef, { suppressBridgeReady: true })

  const win = window as Window & { YabaEditorBridge?: YabaEditorBridge; YabaNoteBridge?: YabaNoteBridge }
  const ed = win.YabaEditorBridge
  if (!ed) return

  wrapSetMarkdownToSyncPreview(ed, opts.setPreviewMarkdown)

  const prevHook = viewActivityRef.current
  viewActivityRef.current = (u: ViewUpdate) => {
    prevHook?.(u)
    if (u.docChanged) {
      queueMicrotask(() => opts.setPreviewMarkdown(ed.getMarkdown()))
    }
  }

  const bridge: YabaNoteBridge = {
    isReady: () => ed.isReady(),
    getSelectionSnapshot: () => ed.getSelectionSnapshot(),
    getSelectedText: () => ed.getSelectedText(),
    setPlatform: (p) => ed.setPlatform(p),
    setAppearance: (m) => ed.setAppearance(m),
    setCursorColor: (c) => ed.setCursorColor(c),
    setWebChromeInsets: (px) => ed.setWebChromeInsets(px),
    setReaderColumnLayout: (layout: ReaderColumnLayoutPayload) => {
      applyReaderColumnLayoutToDocument(layout)
    },
    setReaderPreferences: (prefs) => ed.setReaderPreferences(prefs),
    setEditable: (on) => ed.setEditable(on),
    setPlaceholder: (t) => ed.setPlaceholder(t),
    setMarkdown: (md, o) => ed.setMarkdown(md, o),
    getMarkdown: () => ed.getMarkdown(),
    getUsedInlineAssetSrcs: () => ed.getUsedInlineAssetSrcs(),
    getActiveFormatting: () => ed.getActiveFormatting(),
    focus: () => ed.focus(),
    unFocus: () => ed.unFocus(),
    exportMarkdown: () => ed.exportMarkdown(),
    getSyncedScrollFraction: () => "0",
    setSyncedScrollFraction: () => { },
    dispatch: (payload) => ed.dispatch(payload),
    replaceHighlightColorMark: (from, to, hex) => ed.replaceHighlightColorMark(from, to, hex),
    togglePreviewTaskCheckbox: (bracketOpen: number) => {
      const md = toggleTaskCheckboxInMarkdown(ed.getMarkdown(), bracketOpen)
      ed.setMarkdown(md)
    },
    replacePreviewHighlightSyntax: (
      syntaxStart: number,
      syntaxEnd: number,
      innerStart: number,
      innerEnd: number,
      hexDigitsNoHash: string,
    ) => {
      const digits = String(hexDigitsNoHash ?? "")
        .toLowerCase()
        .replace(/^#/, "")
      const safe = /^[0-9a-f]{6}$/.test(digits) ? digits : "0088ff"
      const md = replaceHighlightSlice(ed.getMarkdown(), syntaxStart, syntaxEnd, innerStart, innerEnd, safe)
      ed.setMarkdown(md)
    },
    setSurfaceMode: (mode: YabaNoteSurfaceMode) => {
      document.documentElement.dataset.yabaNoteSurfaceMode = mode
    },
  }

  delete win.YabaEditorBridge
  win.YabaNoteBridge = bridge

  postToYabaNativeHost({ type: "bridgeReady", feature: "note" })

  queueMicrotask(() => {
    opts.setPreviewMarkdown(ed.getMarkdown())
  })
}
