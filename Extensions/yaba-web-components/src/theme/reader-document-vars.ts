import type { AppearanceMode, Platform } from "./url-params"
import { applyTheme } from "./apply-theme"

/** Matches [ReaderPreferences] / Kotlin [toJsReader*Literal] values. */
export type ReaderThemeName = "system" | "dark" | "light" | "sepia"

/**
 * Darwin `BookmarkDetailReaderChrome.readerSurfaceBackground(.sepia)` —
 * `Color(red: 0.98, green: 0.95, blue: 0.88)` in sRGB.
 */
export const READER_SEPIA_BACKGROUND = "#faf2e0"

/** Web reader ink; Swift uses dynamic label on sepia paper — this keeps markdown readable on cream. */
export const READER_SEPIA_FOREGROUND = "#5b4636"

/** HTML attribute mirrored by [applyReaderThemeCssVars] for CSS / preview hooks. */
export const YABA_READER_THEME_ATTR = "data-yaba-reader-theme"

export interface ReaderTypographyPrefs {
  fontSize: string
  lineHeight: string
}

const readerFontSizeCss: Record<string, string> = {
  small: "16px",
  medium: "18px",
  large: "22px",
}

const readerLineHeightCss: Record<string, string> = {
  normal: "1.6",
  relaxed: "1.8",
}

/** Same as [applyReaderThemeVars] in editor-bridge — sets reader surface colors on :root. */
export function applyReaderThemeCssVars(theme: ReaderThemeName): void {
  const root = document.documentElement
  root.setAttribute(YABA_READER_THEME_ATTR, theme)

  if (theme === "system") {
    root.style.setProperty("--yaba-reader-bg", "transparent")
    root.style.setProperty("--yaba-reader-on-bg", "var(--yaba-on-bg)")
    return
  }

  if (theme === "dark" || theme === "light") {
    root.style.setProperty("--yaba-reader-bg", "var(--yaba-bg)")
    root.style.setProperty("--yaba-reader-on-bg", "var(--yaba-on-bg)")
    return
  }

  root.style.setProperty("--yaba-reader-bg", READER_SEPIA_BACKGROUND)
  root.style.setProperty("--yaba-reader-on-bg", READER_SEPIA_FOREGROUND)
  /*
   * Sepia preview sits on SwiftUI paper behind WKWebView; inside the web shell, Material `--yaba-bg` /
   * `--yaba-surface-variant` were still light-mode lavender greys — reads as "white mode". Align shell
   * tokens with the same cream paper + warm muted surfaces as the reader column.
   */
  root.style.setProperty("--yaba-bg", READER_SEPIA_BACKGROUND)
  root.style.setProperty("--yaba-surface", READER_SEPIA_BACKGROUND)
  root.style.setProperty(
    "--yaba-surface-variant",
    `color-mix(in srgb, ${READER_SEPIA_FOREGROUND} 14%, ${READER_SEPIA_BACKGROUND})`,
  )
}

export function applyReaderTypographyCssVars(prefs: ReaderTypographyPrefs): void {
  const root = document.documentElement
  const fs = prefs.fontSize in readerFontSizeCss ? prefs.fontSize : "medium"
  const lh = prefs.lineHeight in readerLineHeightCss ? prefs.lineHeight : "normal"
  root.style.setProperty("--yaba-reader-font-size", readerFontSizeCss[fs] ?? readerFontSizeCss.medium)
  root.style.setProperty("--yaba-reader-line-height", readerLineHeightCss[lh] ?? readerLineHeightCss.normal)
}

/**
 * Base shell + reader theme pipeline for embedded readers (viewer, editor).
 * When [readerTheme] is system, [shellAppearance] drives light/dark via [applyTheme].
 */
export function applyBaseThemeForReaderTheme(
  platform: Platform,
  shellAppearance: AppearanceMode,
  readerTheme: ReaderThemeName,
  cursorColor: string | null,
): void {
  if (readerTheme === "system") {
    applyTheme(platform, shellAppearance, cursorColor)
  } else if (readerTheme === "dark") {
    applyTheme(platform, "dark", cursorColor)
  } else if (readerTheme === "light") {
    applyTheme(platform, "light", cursorColor)
  } else {
    applyTheme(platform, "light", cursorColor)
  }
}
