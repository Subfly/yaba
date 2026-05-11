import { applyBaseThemeForReaderTheme, applyReaderThemeCssVars, applyReaderTypographyCssVars } from "@/theme/reader-document-vars"
import type { Platform, AppearanceMode } from "@/theme/url-params"
import { applyTheme, parseUrlParams } from "@/theme"
import { publishShellLoad } from "@/bridge/shell-host-events"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"
import type { ReaderPreferences } from "@/bridge/reader-preferences"

export interface ReaderColumnLayoutPayload {
  /** Cap reading column width as a fraction of the WebView viewport (1–100, e.g. 90 ⇒ `90vw`). */
  maxWidthVWPercent: number
  /** Extra horizontal inset (px) inside the scroll view, applied in CSS beside `max-width`. */
  horizontalPaddingPx: number
}

export interface YabaPreviewBridge {
  isReady: () => boolean
  setMarkdown: (markdown: string) => void
  setPlatform: (platform: Platform) => void
  setAppearance: (mode: AppearanceMode) => void
  setCursorColor: (color: string) => void
  setWebChromeInsets: (topChromeInsetPx: number) => void
  setReaderColumnLayout: (layout: ReaderColumnLayoutPayload) => void
  setReaderPreferences: (preferences: Partial<ReaderPreferences>) => void
  /** Normalized `[0,1]` scroll fraction of `.yaba-preview-scroll`. */
  getSyncedScrollFraction: () => string
  /** Apply fractional scroll after switching from editor (layout may lag one frame). */
  setSyncedScrollFraction: (t: number) => void
}

function previewScrollEl(): HTMLElement | null {
  return document.querySelector(".yaba-preview-scroll")
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

export function applyReaderColumnLayoutToDocument(layout: ReaderColumnLayoutPayload): void {
  const root = document.documentElement
  const w = Number.isFinite(layout.maxWidthVWPercent)
    ? Math.max(1, Math.min(100, layout.maxWidthVWPercent))
    : 100
  const p = Number.isFinite(layout.horizontalPaddingPx) ? Math.max(0, layout.horizontalPaddingPx) : 0
  root.style.setProperty("--yaba-reader-column-max-vw", String(w))
  root.style.setProperty("--yaba-reader-column-pad-x-px", String(p))
}

function applyWebChromeInsetsToDocument(topChromeInsetPx: number): void {
  const r = document.documentElement
  const total = Math.max(0, Math.round(topChromeInsetPx))
  r.style.setProperty("--yaba-web-chrome-status-bar", `${total}px`)
  r.style.setProperty("--yaba-web-chrome-top-bar", "0px")
  r.style.setProperty("--yaba-web-chrome-safe-area-top-additional", "0px")
}

let lastReaderMetricsJson: string | null = null

function publishPreviewReaderMetrics(): void {
  const payload = {
    type: "readerMetrics" as const,
    currentPage: 1,
    pageCount: 1,
  }
  const json = JSON.stringify(payload)
  if (json === lastReaderMetricsJson) return
  lastReaderMetricsJson = json
  postToYabaNativeHost(payload)
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
        if (!shellLoadNotified) {
          shellLoadNotified = true
          publishShellLoad("loaded")
        }
        queueMicrotask(() => publishPreviewReaderMetrics())
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
    setReaderColumnLayout: (layout: ReaderColumnLayoutPayload) => {
      applyReaderColumnLayoutToDocument(layout)
    },
    setReaderPreferences: (prefs: Partial<ReaderPreferences>) => {
      readerPreferences = { ...readerPreferences, ...prefs }
      applyReaderPreferences()
    },
    getSyncedScrollFraction: () => {
      try {
        const el = previewScrollEl()
        if (!el) return "0"
        const denom = Math.max(1e-6, el.scrollHeight - el.clientHeight)
        const frac = Math.max(0, Math.min(1, el.scrollTop / denom))
        return String(frac)
      } catch {
        return "0"
      }
    },
    setSyncedScrollFraction: (t: number) => {
      const apply = (): void => {
        try {
          const el = previewScrollEl()
          if (!el) return
          const denom = Math.max(0, el.scrollHeight - el.clientHeight)
          const tt = Number.isFinite(t) ? Math.max(0, Math.min(1, t)) : 0
          el.scrollTo({ top: tt * denom, behavior: "auto" })
        } catch {
          /* ignore */
        }
      }
      apply()
      queueMicrotask(apply)
      requestAnimationFrame(apply)
    },
  }

  postToYabaNativeHost({ type: "bridgeReady", feature: "preview" })
  publishPreviewReaderMetrics()

  return () => {
    setMarkdownState = null
  }
}
