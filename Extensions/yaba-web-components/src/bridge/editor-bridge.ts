import { EditorSelection } from "@codemirror/state"
import type { ViewUpdate } from "@codemirror/view"
import type { EditorSurface } from "@/editor-view/surface"
import {
  collectUsedInlineAssetSrcsFromMarkdown,
  normalizeMarkdownAssetPathsForPersistence,
  rewriteAssetPathsInMarkdown,
} from "@/editor-view/asset-paths"
import type { Platform, AppearanceMode } from "@/theme"
import { applyTheme, parseUrlParams } from "@/theme"
import {
  applyReaderThemeCssVars,
  applyReaderTypographyCssVars,
} from "@/theme/reader-document-vars"
import { getSelectionSnapshotFromView } from "./selection-extractor"
import { getActiveFormattingJson } from "./editor-formatting"
import type { SelectionSnapshot } from "./selection-snapshot"
import {
  publishEditorHostState,
  resetPublishedEditorHostState,
} from "./editor-host-events"
import {
  publishShellLoad,
  scheduleNoteAutosaveAfterEditorActivity,
  setNoteEditorAutosaveIdleEnabled,
} from "./shell-host-events"
import { postToYabaNativeHost } from "./yaba-native-host"
import type { ReaderPreferences } from "./reader-preferences"
import type { EditorCommandPayload } from "./editor-commands"
import { dispatchEditorNativeCommand } from "./editor-native-dispatch"

export type {
  ReaderFontSize,
  ReaderLineHeight,
  ReaderPreferences,
  ReaderTheme,
} from "./reader-preferences"

export interface YabaEditorBridge {
  isReady: () => boolean
  getSelectionSnapshot: () => SelectionSnapshot | null
  getSelectedText: () => string
  setPlatform: (platform: Platform) => void
  setAppearance: (mode: AppearanceMode) => void
  setCursorColor: (color: string) => void
  setWebChromeInsets: (topChromeInsetPx: number) => void
  setReaderPreferences: (preferences: Partial<ReaderPreferences>) => void
  setEditable: (isEditable: boolean) => void
  setPlaceholder: (placeholder: string) => void
  setMarkdown: (markdown: string, options?: { assetsBaseUrl?: string }) => void
  getMarkdown: () => string
  /** JSON array string of canonical `../assets/<id>.<ext>` still referenced in markdown images. */
  getUsedInlineAssetSrcs: () => string
  /** JSON string of toolbar formatting; Markdown editor currently publishes an empty snapshot. */
  getActiveFormatting: () => string
  focus: () => void
  unFocus: () => void
  exportMarkdown: () => string
  /** Normalized `[0,1]` scroll fraction of the Markdown edit surface (Codemirror scroll parent). */
  getSyncedScrollFraction: () => string
  /** Apply fractional scroll `[0,1]` after preview/editor surface switches — best-effort layout match. */
  setSyncedScrollFraction: (t: number) => void
  /** Android `WebViewEditorBridge.dispatch` parity — CodeMirror command wiring lands incrementally. */
  dispatch: (payload: EditorCommandPayload) => void
  /** Replace `{#hex}` token range after native color pick (six lowercase hex digits, no `#`). */
  replaceHighlightColorMark: (from: number, to: number, hexDigits: string) => void
}

/** Set when [setMarkdown] runs with options; used to resolve image paths and normalize saves. */
let lastAssetsBaseUrl: string | undefined

let editorSurface: EditorSurface | null = null
let editorShellLoadNotified = false

/** Latest selection for restoring caret after [unFocus]. */
let lastStoredCursor: { anchor: number; head: number } | null = null

let platform: Platform = "android"
let appearance: AppearanceMode = "auto"
let cursorColor: string | null = null
let readerPreferences: ReaderPreferences = {
  theme: "system",
  fontSize: "medium",
  lineHeight: "normal",
}
let systemColorSchemeMedia: MediaQueryList | null = null
let systemColorSchemeListener: (() => void) | null = null

function clearSystemColorSchemeListener(): void {
  if (!systemColorSchemeMedia || !systemColorSchemeListener) return

  systemColorSchemeMedia.removeEventListener("change", systemColorSchemeListener)
  systemColorSchemeListener = null
  systemColorSchemeMedia = null
}

function ensureSystemColorSchemeListener(): void {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") return
  if (systemColorSchemeListener) return

  systemColorSchemeMedia = window.matchMedia("(prefers-color-scheme: dark)")
  const onChange = () => {
    if (readerPreferences.theme !== "system") return
    applyTheme(platform, appearance, cursorColor)
    applyReaderThemeCssVars(readerPreferences.theme)
    syncEditorCodemirrorDarkTheme()
  }

  systemColorSchemeMedia.addEventListener("change", onChange)
  systemColorSchemeListener = onChange
}

function captureStoredCursorFromView(): void {
  const s = editorSurface
  if (!s) return
  const m = s.view.state.selection.main
  lastStoredCursor = { anchor: m.anchor, head: m.head }
}

function publishCurrentEditorState(): void {
  publishEditorHostState()
}

function focusEditorRestoringCursor(): void {
  const s = editorSurface
  if (!s) return
  try {
    if (lastStoredCursor) {
      const docLen = s.view.state.doc.length
      const { anchor, head } = lastStoredCursor
      const a = Math.max(0, Math.min(anchor, docLen))
      const b = Math.max(0, Math.min(head, docLen))
      const from = Math.min(a, b)
      const to = Math.max(a, b)
      s.view.dispatch({
        selection: EditorSelection.create([EditorSelection.range(from, to)]),
      })
      s.view.focus()
      return
    }
  } catch {
    /* fall through */
  }
  s.view.focus()
}

function applyInitialFocusStateAfterContent(surface: EditorSurface, onApplied?: () => void): void {
  queueMicrotask(() => {
    surface.view.dispatch({ selection: EditorSelection.single(0) })
    captureStoredCursorFromView()
    surface.blur()
    surface.view.scrollDOM.scrollTo({ top: 0, behavior: "auto" })
    onApplied?.()
  })
}

function applyWebChromeInsetsToDocument(topChromeInsetPx: number): void {
  const root = document.documentElement
  const total = Math.max(0, Math.round(topChromeInsetPx))
  root.style.setProperty("--yaba-web-chrome-status-bar", `${total}px`)
  root.style.setProperty("--yaba-web-chrome-top-bar", "0px")
  root.style.setProperty("--yaba-web-chrome-safe-area-top-additional", "0px")
}

function applyReaderPreferences(): void {
  const page = document.body?.dataset.yabaPage
  const useReaderAppearancePipeline = page === "editor" || page === "note"

  if (useReaderAppearancePipeline) {
    if (readerPreferences.theme === "system") {
      applyTheme(platform, appearance, cursorColor)
      if (appearance === "auto") ensureSystemColorSchemeListener()
      else clearSystemColorSchemeListener()
    } else if (readerPreferences.theme === "dark") {
      applyTheme(platform, "dark", cursorColor)
      clearSystemColorSchemeListener()
    } else if (readerPreferences.theme === "light") {
      applyTheme(platform, "light", cursorColor)
      clearSystemColorSchemeListener()
    } else {
      applyTheme(platform, "light", cursorColor)
      clearSystemColorSchemeListener()
    }
  } else {
    applyTheme(platform, appearance, cursorColor)
    clearSystemColorSchemeListener()
  }

  applyReaderThemeCssVars(readerPreferences.theme)
  applyReaderTypographyCssVars(readerPreferences)

  syncEditorCodemirrorDarkTheme()
}

/**
 * Keeps programming-token `HighlightStyle` in sync with reader + shell appearance (requires [EditorView.darkTheme]).
 */
function resolvedEditorAppearanceIsDark(): boolean {
  if (readerPreferences.theme === "dark") return true
  if (readerPreferences.theme === "light" || readerPreferences.theme === "sepia") return false
  /* system */
  if (appearance === "dark") return true
  if (appearance === "light") return false
  if (typeof window !== "undefined" && typeof window.matchMedia === "function") {
    return window.matchMedia("(prefers-color-scheme: dark)").matches
  }
  return false
}

function syncEditorCodemirrorDarkTheme(): void {
  if (!editorSurface) return
  const page = document.body?.dataset.yabaPage
  if (page !== "editor" && page !== "note") return
  editorSurface.syncCodemirrorDarkTheme(resolvedEditorAppearanceIsDark())
}

function wireViewActivity(viewActivityRef: { current: ((u: ViewUpdate) => void) | null }): void {
  viewActivityRef.current = (u: ViewUpdate) => {
    if (u.selectionSet || u.focusChanged) {
      captureStoredCursorFromView()
    }
    if (u.selectionSet || u.focusChanged || u.docChanged) {
      publishCurrentEditorState()
    }
    if (u.docChanged) {
      scheduleNoteAutosaveAfterEditorActivity()
    }
  }
}

export type InitEditorBridgeOptions = {
  /** When true, skip posting `bridgeReady` (unified `note.html` posts `feature: "note"`). */
  suppressBridgeReady?: boolean
}

export function initEditorBridge(
  surface: EditorSurface,
  viewActivityRef: { current: ((u: ViewUpdate) => void) | null },
  options?: InitEditorBridgeOptions,
): void {
  editorSurface = surface
  editorShellLoadNotified = false
  setNoteEditorAutosaveIdleEnabled(false)
  resetPublishedEditorHostState()
  wireViewActivity(viewActivityRef)

  const urlParams = parseUrlParams()
  platform = urlParams.platform
  appearance = urlParams.appearance

  applyInitialFocusStateAfterContent(surface, () => {
    publishCurrentEditorState()
  })

  const win = window as Window & { YabaEditorBridge?: YabaEditorBridge }
  win.YabaEditorBridge = {
    isReady: () => !!editorSurface,
    getSelectionSnapshot: () => getSelectionSnapshotFromView(editorSurface?.view ?? null),
    getSelectedText: () => {
      const v = editorSurface?.view
      if (!v) return ""
      const m = v.state.selection.main
      if (m.empty) return ""
      return v.state.doc.sliceString(m.from, m.to).trim()
    },
    setPlatform: (p: Platform) => {
      platform = p
      applyReaderPreferences()
    },
    setAppearance: (mode: AppearanceMode) => {
      appearance = mode
      applyReaderPreferences()
    },
    setCursorColor: (color: string) => {
      cursorColor = color
      applyReaderPreferences()
    },
    setWebChromeInsets: (topChromeInsetPx: number) => {
      applyWebChromeInsetsToDocument(topChromeInsetPx)
    },
    setReaderPreferences: (prefs: Partial<ReaderPreferences>) => {
      readerPreferences = {
        ...readerPreferences,
        ...prefs,
      }
      applyReaderPreferences()
    },
    setEditable: (isEditable: boolean) => {
      editorSurface?.setEditable(isEditable)
    },
    setPlaceholder: (placeholder: string) => {
      editorSurface?.setPlaceholder(placeholder)
      publishCurrentEditorState()
    },
    setMarkdown: (markdown: string, options?: { assetsBaseUrl?: string }) => {
      const s = editorSurface
      if (!s) return
      try {
        setNoteEditorAutosaveIdleEnabled(false)
        if (options?.assetsBaseUrl) {
          lastAssetsBaseUrl = options.assetsBaseUrl
        }
        let md = markdown?.trim() ? markdown : ""
        if (options?.assetsBaseUrl && md.includes("../assets/")) {
          md = rewriteAssetPathsInMarkdown(md, options.assetsBaseUrl)
        }
        s.setMarkdown(md)
        applyInitialFocusStateAfterContent(s, () => {
          publishCurrentEditorState()
        })
        if (!editorShellLoadNotified) {
          editorShellLoadNotified = true
          publishShellLoad("loaded")
        }
        queueMicrotask(() => {
          const page = document.body?.dataset.yabaPage
          if (page === "editor" || page === "note") {
            setNoteEditorAutosaveIdleEnabled(true)
          }
        })
      } catch {
        if (!editorShellLoadNotified) {
          editorShellLoadNotified = true
          publishShellLoad("error")
        }
      }
    },
    getMarkdown: () => {
      const raw = editorSurface?.getMarkdown() ?? ""
      return normalizeMarkdownAssetPathsForPersistence(raw, lastAssetsBaseUrl)
    },
    getUsedInlineAssetSrcs: () => {
      const raw = editorSurface?.getMarkdown() ?? ""
      const normalized = normalizeMarkdownAssetPathsForPersistence(raw, lastAssetsBaseUrl)
      const list = collectUsedInlineAssetSrcsFromMarkdown(normalized, lastAssetsBaseUrl)
      return JSON.stringify(list)
    },
    getActiveFormatting: () => getActiveFormattingJson(),
    focus: () => {
      focusEditorRestoringCursor()
      publishCurrentEditorState()
    },
    unFocus: () => {
      captureStoredCursorFromView()
      editorSurface?.blur()
      publishCurrentEditorState()
    },
    exportMarkdown: () => {
      const md = win.YabaEditorBridge?.getMarkdown() ?? ""
      return md.trimEnd() + "\n"
    },
    getSyncedScrollFraction: () => {
      try {
        const dom = editorSurface?.view.scrollDOM
        if (!dom) return "0"
        const denom = Math.max(1e-6, dom.scrollHeight - dom.clientHeight)
        const t = Math.max(0, Math.min(1, dom.scrollTop / denom))
        return String(t)
      } catch {
        return "0"
      }
    },
    setSyncedScrollFraction: (t: number) => {
      try {
        const dom = editorSurface?.view.scrollDOM
        if (!dom) return
        const denom = Math.max(0, dom.scrollHeight - dom.clientHeight)
        const tt = Number.isFinite(t) ? Math.max(0, Math.min(1, t)) : 0
        dom.scrollTo({ top: tt * denom, behavior: "auto" })
        requestAnimationFrame(() => {
          const d2 = editorSurface?.view.scrollDOM
          if (!d2) return
          const denom2 = Math.max(0, d2.scrollHeight - d2.clientHeight)
          d2.scrollTo({ top: tt * denom2, behavior: "auto" })
        })
      } catch {
        /* ignore */
      }
    },
    dispatch: (payload: EditorCommandPayload) => {
      dispatchEditorNativeCommand(editorSurface?.view ?? null, payload)
      scheduleNoteAutosaveAfterEditorActivity()
    },
    replaceHighlightColorMark: (from: number, to: number, hexDigits: string) => {
      const v = editorSurface?.view
      if (!v) return
      let digits = String(hexDigits ?? "")
        .toLowerCase()
        .replace(/^#/, "")
      if (!/^[0-9a-f]{6}$/.test(digits)) digits = "0088ff"
      const insert = `{#${digits}}`
      const docLen = v.state.doc.length
      const f = Math.max(0, Math.min(Math.floor(from), docLen))
      const t = Math.max(f, Math.min(Math.floor(to), docLen))
      v.dispatch({
        changes: { from: f, to: t, insert },
        selection: EditorSelection.cursor(f + insert.length),
      })
      v.focus()
      scheduleNoteAutosaveAfterEditorActivity()
    },
  }

  applyReaderPreferences()

  if (document.body?.dataset.yabaPage === "editor" && !options?.suppressBridgeReady) {
    postToYabaNativeHost({ type: "bridgeReady", feature: "editor" })
  }
}
