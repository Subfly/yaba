import { applyBaseThemeForReaderTheme, applyReaderThemeCssVars, applyReaderTypographyCssVars } from "@/theme/reader-document-vars"
import type { Platform, AppearanceMode } from "@/theme/url-params"
import { applyTheme, parseUrlParams } from "@/theme"
import { buildHeadingTocFromMarkdown } from "@/editor-view/toc-from-markdown"
import { publishShellLoad } from "@/bridge/shell-host-events"
import { publishToc, resetPublishedToc } from "@/bridge/toc-host-events"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"
import type { ReaderPreferences } from "@/bridge/read-it-later-bridge"
import { getDomSelectionSnapshot } from "@/bridge/dom-selection-snapshot"
import type { AnnotationForRendering } from "@/bridge/read-it-later-types"
import {
  applyAnnotationColorDecorations,
  domSelectionOverlapsAnnotation,
} from "@/bridge/read-it-later-annotations"

export interface YabaPreviewBridge {
  isReady: () => boolean
  setMarkdown: (markdown: string) => void
  setPlatform: (platform: Platform) => void
  setAppearance: (mode: AppearanceMode) => void
  setCursorColor: (color: string) => void
  setWebChromeInsets: (topChromeInsetPx: number) => void
  setReaderPreferences: (preferences: Partial<ReaderPreferences>) => void
  setAnnotations: (annotationsJson: string) => void
  scrollToAnnotation: (annotationId: string) => void
  navigateToTocItem: (tocItemId: string, _extrasJson?: string | null) => void
  getSelectionSnapshot: () => ReturnType<typeof getDomSelectionSnapshot>
  getSelectedText: () => string
  getCanCreateAnnotation: () => boolean
}

let latestMarkdown = ""
let shellLoadNotified = false
let platform: Platform = "darwin"
let appearance: AppearanceMode = "auto"
let cursorColor: string | null = null
let readerPreferences: ReaderPreferences = {
  theme: "system",
  fontSize: "medium",
  lineHeight: "normal",
}

let setMarkdownState: ((md: string) => void) | null = null

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

function applyReaderPreferences(): void {
  if (readerPreferences.theme === "system") {
    applyBaseThemeForReaderTheme(platform, appearance, readerPreferences.theme, cursorColor)
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
  applyReaderThemeCssVars(readerPreferences.theme)
  applyReaderTypographyCssVars({
    fontSize: readerPreferences.fontSize,
    lineHeight: readerPreferences.lineHeight,
  })
}

function applyWebChromeInsetsToDocument(topChromeInsetPx: number): void {
  const r = document.documentElement
  const total = Math.max(0, Math.round(topChromeInsetPx))
  r.style.setProperty("--yaba-web-chrome-status-bar", `${total}px`)
  r.style.setProperty("--yaba-web-chrome-top-bar", "0px")
  r.style.setProperty("--yaba-web-chrome-safe-area-top-additional", "0px")
}

function previewMarkdownRoot(): HTMLElement | null {
  return document.querySelector(".yaba-preview-scroll .yaba-markdown-preview") as HTMLElement | null
}

let storedAnnotations: AnnotationForRendering[] = []

function cssEscapeForSelector(value: string): string {
  if (typeof CSS !== "undefined" && typeof CSS.escape === "function") {
    return CSS.escape(value)
  }
  return value.replace(/["\\]/g, "\\$&")
}

function onPreviewAnnotationClick(ev: MouseEvent): void {
  const root = previewMarkdownRoot()
  if (!root || !root.contains(ev.target as Node)) return
  const t = (ev.target as HTMLElement | null)?.closest?.(
    ".yaba-annotation-decoration[data-annotation-id]",
  ) as HTMLElement | null
  if (!t) return
  const id = t.getAttribute("data-annotation-id")
  if (!id) return
  ev.preventDefault()
  postToYabaNativeHost({ type: "annotationTap", id })
}

function getPreviewCanCreateAnnotationInner(): boolean {
  const root = previewMarkdownRoot()
  if (!root) return false
  const sel = window.getSelection()
  if (!sel || sel.rangeCount === 0) return false
  const range = sel.getRangeAt(0)
  if (range.collapsed) return false
  if (!root.contains(range.commonAncestorContainer)) return false
  if (domSelectionOverlapsAnnotation(root, range)) return false
  return true
}

let lastReaderMetricsJson: string | null = null

function publishPreviewReaderMetrics(): void {
  const payload = {
    type: "readerMetrics" as const,
    canCreateAnnotation: getPreviewCanCreateAnnotationInner(),
    currentPage: 1,
    pageCount: 1,
  }
  const json = JSON.stringify(payload)
  if (json === lastReaderMetricsJson) return
  lastReaderMetricsJson = json
  postToYabaNativeHost(payload)
}

function scheduleApplyStoredAnnotations(): void {
  requestAnimationFrame(() => {
    const root = previewMarkdownRoot()
    if (root && storedAnnotations.length > 0) {
      applyAnnotationColorDecorations(root, storedAnnotations)
    }
    publishPreviewReaderMetrics()
  })
}

const TOC_DEBOUNCE_MS = 350
let tocTimer: ReturnType<typeof setTimeout> | null = null

function clearTocTimer(): void {
  if (tocTimer !== null) {
    clearTimeout(tocTimer)
    tocTimer = null
  }
}

function scheduleTocPublish(md: string): void {
  clearTocTimer()
  tocTimer = setTimeout(() => {
    tocTimer = null
    const toc = buildHeadingTocFromMarkdown(md)
    publishToc(toc)
  }, TOC_DEBOUNCE_MS)
}

/** Wire native `evaluateJavaScript` targets for the markdown preview shell. */
export function initPreviewBridge(api: { setMarkdownState: (md: string) => void }): () => void {
  setMarkdownState = api.setMarkdownState

  const params = parseUrlParams()
  platform = params.platform
  appearance = params.appearance
  cursorColor = params.cursorColor
  try {
    applyTheme(platform, appearance, cursorColor)
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error("[YABA preview] theme", e)
  }
  applyReaderPreferences()

  const win = window as Window & { YabaPreviewBridge?: YabaPreviewBridge }
  win.YabaPreviewBridge = {
    isReady: () => true,
    setMarkdown: (markdown: string) => {
      try {
        latestMarkdown = markdown ?? ""
        setMarkdownState?.(latestMarkdown)
        resetPublishedToc()
        if (!shellLoadNotified) {
          shellLoadNotified = true
          publishShellLoad("loaded")
        }
        scheduleTocPublish(latestMarkdown)
        queueMicrotask(() => scheduleApplyStoredAnnotations())
      } catch {
        if (!shellLoadNotified) {
          shellLoadNotified = true
          publishShellLoad("error")
        }
      }
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
      readerPreferences = { ...readerPreferences, ...prefs }
      applyReaderPreferences()
    },
    setAnnotations: (annotationsJson: string) => {
      try {
        storedAnnotations =
          annotationsJson && annotationsJson.trim() ? JSON.parse(annotationsJson) : []
      } catch {
        storedAnnotations = []
      }
      scheduleApplyStoredAnnotations()
    },
    scrollToAnnotation: (annotationId: string) => {
      const root = previewMarkdownRoot()
      if (!root) return
      const el = root.querySelector(
        `.yaba-annotation-decoration[data-annotation-id="${cssEscapeForSelector(annotationId)}"]`,
      ) as HTMLElement | null
      el?.scrollIntoView({ behavior: "smooth", block: "center" })
    },
    navigateToTocItem: (tocItemId: string) => {
      document.getElementById(tocItemId)?.scrollIntoView({ behavior: "smooth", block: "center" })
    },
    getSelectionSnapshot: () => {
      const root = previewMarkdownRoot()
      return root ? getDomSelectionSnapshot(root) : null
    },
    getSelectedText: () => getDomSelectionSnapshot(previewMarkdownRoot())?.selectedText ?? "",
    getCanCreateAnnotation: () => getPreviewCanCreateAnnotationInner(),
  }

  document.addEventListener("selectionchange", publishPreviewReaderMetrics)
  document.addEventListener("click", onPreviewAnnotationClick)

  postToYabaNativeHost({ type: "bridgeReady", feature: "preview" })
  publishPreviewReaderMetrics()

  return () => {
    document.removeEventListener("selectionchange", publishPreviewReaderMetrics)
    document.removeEventListener("click", onPreviewAnnotationClick)
    clearTocTimer()
    setMarkdownState = null
  }
}
