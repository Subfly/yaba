import { HighlightStyle } from "@codemirror/language"
import { markdownLanguage } from "@codemirror/lang-markdown"
import { tags as t } from "@lezer/highlight"
import { yabaMathFenceTag, yabaMathShellTag } from "./yaba-markdown-math-extension"

/**
 * Class hooks for Markdown (GFM); colors and scale live in `editor-view.css`.
 * Scoped so fenced code stays on `defaultHighlightStyle` (only font is set in `editor-code-fonts.ts`).
 */
export const yabaMarkdownHighlightClasses = HighlightStyle.define(
  [
    { tag: t.heading1, class: "yaba-md-h1" },
    { tag: t.heading2, class: "yaba-md-h2" },
    { tag: t.heading3, class: "yaba-md-h3" },
    { tag: t.heading4, class: "yaba-md-h4" },
    { tag: t.heading5, class: "yaba-md-h5" },
    { tag: t.heading6, class: "yaba-md-h6" },
    { tag: t.emphasis, class: "yaba-md-emphasis" },
    { tag: t.strong, class: "yaba-md-strong" },
    { tag: t.strikethrough, class: "yaba-md-strike" },
    { tag: t.link, class: "yaba-md-link" },
    { tag: t.url, class: "yaba-md-url" },
    { tag: t.list, class: "yaba-md-list" },
    { tag: t.quote, class: "yaba-md-quote" },
    { tag: t.labelName, class: "yaba-md-label" },
    { tag: t.string, class: "yaba-md-string" },
    { tag: t.comment, class: "yaba-md-comment" },
    /* #, >, -, *, ``, [](), etc. */
    { tag: t.processingInstruction, class: "yaba-md-syntax-mark" },
    { tag: t.escape, class: "yaba-md-escape" },
    { tag: t.character, class: "yaba-md-entity" },
    { tag: yabaMathShellTag, class: "yaba-md-math" },
    { tag: yabaMathFenceTag, class: "yaba-md-math-mark" },
  ],
  { scope: markdownLanguage }
)
