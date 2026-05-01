import ePub, { type Book, type Contents, type Location, type Rendition } from "epubjs"
import { type AppearanceMode, applyTheme, type Platform } from "@/theme"
import {
  applyBaseThemeForReaderTheme,
  applyReaderThemeCssVars,
  applyReaderTypographyCssVars,
  type ReaderThemeName,
} from "@/theme/reader-document-vars"
import { getEpubContentOverrideCss } from "./epub-content-styles"
import { publishShellLoad } from "@/bridge/shell-host-events"
import { publishEpubReaderMetrics } from "@/bridge/reader-metrics-host"
import { publishToc, resetPublishedToc, type TocItemJson, type TocJson } from "@/bridge/toc-host-events"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"

interface ReaderPreferencesInput {
  theme?: string
  fontSize?: string
  lineHeight?: string
}

interface YabaEpubBridge {
  isReady: () => boolean
  setEpubUrl: (url: string) => boolean
  getCurrentPageNumber: () => number
  getPageCount: () => number
  nextPage: () => boolean
  prevPage: () => boolean
  setPlatform: (platform: Platform) => void
  setAppearance: (appearance: AppearanceMode) => void
  setReaderPreferences: (preferences: Partial<ReaderPreferencesInput>) => void
  navigateToTocItem: (id: string, extrasJson?: string | null) => void
}

interface EpubNavItem {
  href?: string
  label?: string
  subitems?: EpubNavItem[]
}

/** True after [initEpubViewerBridge] installed `window.YabaEpubBridge` (matches PDF viewer — host must see ready before calling setEpubUrl). */
let shellReady = false
let currentPlatform: Platform = "android"
let currentAppearance: AppearanceMode = "auto"
let book: Book | null = null
let rendition: Rendition | null = null
let currentPageNum = 1
let spineLength = 1
let lastRelocatedStartCfi: string | null = null
let viewportRecoveryTimer: ReturnType<typeof setTimeout> | null = null
let viewportStabilityHandlersInstalled = false

interface MergedEpubReaderPrefs {
  theme: ReaderThemeName
  fontSize: string
  lineHeight: string
}

let mergedReaderPrefs: MergedEpubReaderPrefs = {
  theme: "system",
  fontSize: "medium",
  lineHeight: "normal",
}

let epubSystemMedia: MediaQueryList | null = null
let epubSystemListener: (() => void) | null = null

function clearEpubSystemColorSchemeListener(): void {
  if (!epubSystemMedia || !epubSystemListener) return
  epubSystemMedia.removeEventListener("change", epubSystemListener)
  epubSystemListener = null
  epubSystemMedia = null
}

function ensureEpubSystemColorSchemeListener(): void {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") return
  if (mergedReaderPrefs.theme !== "system") return
  if (epubSystemListener) return

  epubSystemMedia = window.matchMedia("(prefers-color-scheme: dark)")
  const onChange = () => {
    if (mergedReaderPrefs.theme !== "system") return
    applyTheme(currentPlatform, currentAppearance, null)
    applyReaderThemeCssVars("system")
    applyReaderTypographyCssVars(mergedReaderPrefs)
    syncReaderVarsIntoAllEpubContents()
  }
  epubSystemMedia.addEventListener("change", onChange)
  epubSystemListener = onChange
}

function normalizeReaderTheme(t: string | undefined): ReaderThemeName {
  if (t === "dark" || t === "light" || t === "sepia" || t === "system") return t
  return "system"
}

/** Applies shell palette + reader CSS vars on the host document (iframe content synced separately). */
function applyEpubReaderPipeline(): void {
  const theme = mergedReaderPrefs.theme
  applyBaseThemeForReaderTheme(currentPlatform, currentAppearance, theme, null)
  if (theme === "system") {
    if (currentAppearance === "auto") ensureEpubSystemColorSchemeListener()
    else clearEpubSystemColorSchemeListener()
  } else {
    clearEpubSystemColorSchemeListener()
  }
  applyReaderThemeCssVars(theme)
  applyReaderTypographyCssVars(mergedReaderPrefs)
  const root = document.getElementById("epub-root")
  if (root) {
    root.style.background = "var(--yaba-reader-bg, transparent)"
  }
  syncReaderVarsIntoAllEpubContents()
}

function syncReaderVarsFromHostToIframeDoc(doc: Document): void {
  const host = document.documentElement
  const iframeRoot = doc.documentElement
  const cs = getComputedStyle(host)

  iframeRoot.setAttribute("data-yaba-reader-theme", mergedReaderPrefs.theme)

  const shared = [
    "--yaba-reader-font-size",
    "--yaba-reader-line-height",
    "--yaba-font-family",
    "--yaba-primary",
  ] as const
  for (const name of shared) {
    const v = cs.getPropertyValue(name).trim()
    if (v !== "") iframeRoot.style.setProperty(name, v)
  }

  if (mergedReaderPrefs.theme === "system") {
    /**
     * Read-it-later [read-it-later.html] is one document: --yaba-reader-bg stays transparent and Compose shows through.
     * EPUB spine documents live in iframes; transparency does not reveal the host surface, so the canvas stays
     * effectively light and resolved --yaba-on-bg (e.g. dark mode) reads as pale text on white. Map system theme
     * to the same resolved shell palette as [applyTheme] (--yaba-bg / --yaba-on-bg) for correct contrast.
     */
    const shellBg = cs.getPropertyValue("--yaba-bg").trim()
    const shellOnBg = cs.getPropertyValue("--yaba-on-bg").trim()
    if (shellBg !== "") iframeRoot.style.setProperty("--yaba-reader-bg", shellBg)
    if (shellOnBg !== "") iframeRoot.style.setProperty("--yaba-reader-on-bg", shellOnBg)
  } else {
    const rb = cs.getPropertyValue("--yaba-reader-bg").trim()
    const rob = cs.getPropertyValue("--yaba-reader-on-bg").trim()
    if (rb !== "") iframeRoot.style.setProperty("--yaba-reader-bg", rb)
    if (rob !== "") iframeRoot.style.setProperty("--yaba-reader-on-bg", rob)
  }
}

function getRenditionContentsList(r: Rendition): Contents[] {
  const raw = r.getContents() as unknown
  return Array.isArray(raw) ? (raw as Contents[]) : []
}

function mapEpubNavToToc(items: EpubNavItem[], depth: number, path: string): TocItemJson[] {
  if (!Array.isArray(items) || items.length === 0) return []
  return items.map((item, i) => {
    const href = (item.href ?? "").trim()
    const id = `${path}-${i}-${href || "nohref"}`
    const title = (item.label ?? "").trim() || "Untitled"
    const extrasJson = href.length > 0 ? JSON.stringify({ href }) : null
    const children = mapEpubNavToToc(item.subitems ?? [], depth + 1, id)
    return {
      id,
      title,
      level: depth,
      children,
      extrasJson,
    }
  })
}

async function buildAndPublishEpubToc(b: Book): Promise<void> {
  try {
    resetPublishedToc()
    const navigation = await b.loaded.navigation
    const raw = navigation?.toc as EpubNavItem[] | undefined
    if (!raw || raw.length === 0) {
      publishToc({ items: [] })
      return
    }
    const items = mapEpubNavToToc(raw, 1, "epub")
    publishToc({ items } satisfies TocJson)
  } catch {
    publishToc({ items: [] })
  }
}

function syncReaderVarsIntoAllEpubContents(): void {
  const r = rendition
  if (!r) return
  for (const contents of getRenditionContentsList(r)) {
    try {
      syncReaderVarsFromHostToIframeDoc(contents.document)
    } catch {
      /* ignore */
    }
  }
}

function clearViewportRecoveryTimer(): void {
  if (viewportRecoveryTimer) {
    clearTimeout(viewportRecoveryTimer)
    viewportRecoveryTimer = null
  }
}

/**
 * Android IME insets can resize the WebView while creation UI is focused.
 * epub.js may relocate to a previous spread after that resize, so we redisplay
 * the last known CFI once the viewport settles.
 */
function scheduleViewportLocationRecovery(): void {
  clearViewportRecoveryTimer()
  viewportRecoveryTimer = setTimeout(() => {
    viewportRecoveryTimer = null
    const cfi = lastRelocatedStartCfi
    const r = rendition
    if (!r || !cfi) return
    void r.display(cfi)
  }, 220)
}

function ensureViewportStabilityHandlers(): void {
  if (viewportStabilityHandlersInstalled || typeof window === "undefined") return
  viewportStabilityHandlersInstalled = true
  const onResize = () => scheduleViewportLocationRecovery()
  window.addEventListener("resize", onResize, { passive: true })
  window.visualViewport?.addEventListener("resize", onResize, { passive: true })
}

export function initEpubViewerBridge(platform: Platform, appearance: AppearanceMode): void {
  currentPlatform = platform
  currentAppearance = appearance
  applyTheme(currentPlatform, currentAppearance, null)
  mergedReaderPrefs = {
    theme: "system",
    fontSize: "medium",
    lineHeight: "normal",
  }
  applyEpubReaderPipeline()
  ensureViewportStabilityHandlers()

  const win = window as Window & { YabaEpubBridge?: YabaEpubBridge }

  win.YabaEpubBridge = {
    isReady: () => shellReady,
    setEpubUrl(url: string): boolean {
      if (!url) return false
      void (async () => {
        try {
          resetPublishedToc()
          clearViewportRecoveryTimer()
          lastRelocatedStartCfi = null
          if (rendition) {
            try {
              rendition.destroy()
            } catch {
              /* ignore */
            }
          }
          rendition = null
          if (book) {
            try {
              book.destroy()
            } catch {
              /* ignore */
            }
          }
          book = null

          const root = document.getElementById("epub-root")
          if (!root) {
            publishShellLoad("error")
            return
          }
          root.innerHTML = ""

          book = ePub(url)
          await book.ready
          const spineItems = await book.loaded.spine
          spineLength = Math.max(1, spineItems.length)

          await buildAndPublishEpubToc(book)

          rendition = book.renderTo(root, {
            width: "100%",
            height: "100%",
            flow: "paginated",
            allowScriptedContent: false,
          })

          rendition.hooks.content.register((contents: Contents) => {
            const doc = contents.document
            syncReaderVarsFromHostToIframeDoc(doc)
            const style = doc.createElement("style")
            style.id = "yaba-epub-content-style"
            style.textContent = getEpubContentOverrideCss()
            doc.head.appendChild(style)
          })

          rendition.on("relocated", (location: Location) => {
            const relocatedCfi = location.start.cfi
            if (typeof relocatedCfi === "string" && relocatedCfi.trim().length > 0) {
              lastRelocatedStartCfi = relocatedCfi
            }
            const relocatedIndex = location.start.index
            if (typeof relocatedIndex === "number" && Number.isFinite(relocatedIndex)) {
              currentPageNum = relocatedIndex + 1
            }
            queueMicrotask(() => publishEpubReaderMetrics())
          })

          await rendition.display()
          currentPageNum = 1
          syncReaderVarsIntoAllEpubContents()
          publishShellLoad("loaded")
        } catch (e) {
          console.error("EPUB load failed", e)
          resetPublishedToc()
          publishToc({ items: [] })
          publishShellLoad("error")
        }
      })()
      return true
    },
    getCurrentPageNumber(): number {
      return currentPageNum
    },
    getPageCount(): number {
      return spineLength
    },
    nextPage(): boolean {
      if (!rendition) return false
      void rendition.next()
      return true
    },
    prevPage(): boolean {
      if (!rendition) return false
      void rendition.prev()
      return true
    },
    setPlatform(platform: Platform): void {
      currentPlatform = platform
      applyEpubReaderPipeline()
    },
    setAppearance(appearance: AppearanceMode): void {
      currentAppearance = appearance
      applyEpubReaderPipeline()
    },
    setReaderPreferences(prefs: Partial<ReaderPreferencesInput>): void {
      mergedReaderPrefs = {
        theme: normalizeReaderTheme(prefs.theme ?? mergedReaderPrefs.theme),
        fontSize: prefs.fontSize ?? mergedReaderPrefs.fontSize,
        lineHeight: prefs.lineHeight ?? mergedReaderPrefs.lineHeight,
      }
      applyEpubReaderPipeline()
    },
    navigateToTocItem(_id: string, extrasJson?: string | null): void {
      const r = rendition
      if (!r) return
      try {
        const raw = extrasJson?.trim()
        if (!raw) return
        const o = JSON.parse(raw) as { href?: string }
        const href = o.href
        if (!href || typeof href !== "string") return
        void r.display(href)
      } catch {
        /* ignore */
      }
    },
  }
  shellReady = true
  postToYabaNativeHost({ type: "bridgeReady", feature: "epub" })
}
