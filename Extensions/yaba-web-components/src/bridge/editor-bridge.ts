import { EditorSelection } from "@codemirror/state"
import type { ViewUpdate } from "@codemirror/view"
import type { EditorSurface } from "@/editor-view/surface"
import {
  collectUsedInlineAssetSrcsFromMarkdown,
  normalizeMarkdownAssetPathsForPersistence,
  rewriteAssetPathsInMarkdown,
} from "@/editor-view/asset-paths"
import { buildHeadingTocFromMarkdown, findHeadingOffsetForTocItemId } from "@/editor-view/toc-from-markdown"
import type { AnnotationForRendering } from "@/editor-view/annotation-extension"
import { annotationModel, selectionOverlapsAnnotationRange } from "@/editor-view/annotation-extension"
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
import { publishToc, resetPublishedToc } from "./toc-host-events"
import { postToYabaNativeHost } from "./yaba-native-host"

export type ReaderTheme = "system" | "dark" | "light" | "sepia"
export type ReaderFontSize = "small" | "medium" | "large"
export type ReaderLineHeight = "normal" | "relaxed"

export interface ReaderPreferences {
  theme: ReaderTheme
  fontSize: ReaderFontSize
  lineHeight: ReaderLineHeight
}

export interface YabaEditorBridge {
  isReady: () => boolean
  getSelectionSnapshot: () => SelectionSnapshot | null
  getSelectedText: () => string
  getCanCreateAnnotation: () => boolean
  setAnnotations: (annotationsJson: string) => void
  scrollToAnnotation: (annotationId: string) => void
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
  applyAnnotationToSelection: (annotationId: string) => boolean
  removeAnnotationFromDocument: (annotationId: string) => number
  onAnnotationTap?: (id: string) => void
  navigateToTocItem: (id: string, extrasJson?: string | null) => void
}

/** Set when [setMarkdown] runs with options; used to resolve image paths and normalize saves. */
let lastAssetsBaseUrl: string | undefined

let editorSurface: EditorSurface | null = null
let editorShellLoadNotified = false
let tocPublishTimer: ReturnType<typeof setTimeout> | null = null
const TOC_PUBLISH_DEBOUNCE_MS = 1000

function clearTocPublishTimer(): void {
  if (tocPublishTimer !== null) {
    clearTimeout(tocPublishTimer)
    tocPublishTimer = null
  }
}

function scheduleHeadingTocPublish(): void {
  const page = typeof document !== "undefined" ? document.body?.dataset.yabaPage : undefined
  if (page !== "editor") return
  clearTocPublishTimer()
  tocPublishTimer = setTimeout(() => {
    tocPublishTimer = null
    publishHeadingTocFromMarkdownSource()
  }, TOC_PUBLISH_DEBOUNCE_MS)
}

function publishHeadingTocFromMarkdownSource(): void {
  const s = editorSurface
  if (!s) {
    publishToc(null)
    return
  }
  const toc = buildHeadingTocFromMarkdown(s.getMarkdown())
  publishToc(toc)
}

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

function getCanCreateAnnotationForCurrentSelection(): boolean {
  const s = editorSurface
  if (!s) return false
  const m = s.view.state.selection.main
  if (m.empty) return false
  const page = document.body?.dataset.yabaPage
  if (page === "editor") return true
  const ranges = s.view.state.field(annotationModel).ranges
  return !selectionOverlapsAnnotationRange(ranges, m.from, m.to)
}

function publishCurrentEditorState(): void {
  publishEditorHostState(getCanCreateAnnotationForCurrentSelection)
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
  const useReaderAppearancePipeline = page === "editor"

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
      scheduleHeadingTocPublish()
    }
  }
}

export function initEditorBridge(
  surface: EditorSurface,
  viewActivityRef: { current: ((u: ViewUpdate) => void) | null },
): void {
  editorSurface = surface
  editorShellLoadNotified = false
  clearTocPublishTimer()
  resetPublishedToc()
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
    getCanCreateAnnotation: () => getCanCreateAnnotationForCurrentSelection(),
    setAnnotations: (annotationsJson: string) => {
      try {
        const annotations: AnnotationForRendering[] =
          annotationsJson && annotationsJson.trim() ? JSON.parse(annotationsJson) : []
        editorSurface?.setAnnotationPalette(annotations)
      } catch {
        editorSurface?.setAnnotationPalette([])
      }
    },
    scrollToAnnotation: (annotationId: string) => {
      editorSurface?.scrollToAnnotation(annotationId)
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
        s.setMarkdown(md, { resetAnnotations: true })
        applyInitialFocusStateAfterContent(s, () => {
          publishCurrentEditorState()
        })
        if (!editorShellLoadNotified) {
          editorShellLoadNotified = true
          publishShellLoad("loaded")
        }
        queueMicrotask(() => {
          publishHeadingTocFromMarkdownSource()
          if (document.body?.dataset.yabaPage === "editor") {
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
    applyAnnotationToSelection: (annotationId: string) => {
      const s = editorSurface
      if (!s) return false
      return s.applyAnnotationToSelection(annotationId)
    },
    removeAnnotationFromDocument: (annotationId: string) =>
      editorSurface?.removeAnnotationFromDocument(annotationId) ?? 0,
    navigateToTocItem: (id: string, _extrasJson?: string | null) => {
      const s = editorSurface
      if (!s) return
      const md = s.getMarkdown()
      const pos = findHeadingOffsetForTocItemId(md, id)
      if (pos == null) return
      s.scrollPosIntoView(pos)
    },
  }

  applyReaderPreferences()

  if (document.body?.dataset.yabaPage === "editor") {
    postToYabaNativeHost({ type: "bridgeReady", feature: "editor" })
  }
}
