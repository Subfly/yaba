import { syntaxHighlighting } from "@codemirror/language"
import { markdown, markdownLanguage } from "@codemirror/lang-markdown"
import { languages } from "@codemirror/language-data"
import { Compartment, EditorState, type Extension } from "@codemirror/state"
import { EditorView, placeholder } from "@codemirror/view"

import { markdownCodeFontFaces, embeddedCodeFontFaces } from "./editor-code-fonts"
import { YABA_EDITOR_BASIC_SETUP } from "./yaba-basic-setup"
import { yabaMarkdownHighlightClasses } from "./yaba-markdown-highlight-classes"
import { yabaMarkdownMathExtensions } from "./yaba-markdown-math-extension"
import {
  yabaDarkCodeHighlightStyle,
  yabaLightCodeHighlightStyle,
} from "./yaba-code-highlight-styles"

export interface YabaEditorExtensionCompartments {
  placeholder: Compartment
  editable: Compartment
  /** Hook point for custom parsing, widgets, previews, and future YABA layers. */
  yabaExtras: Compartment
  /** Gates `HighlightStyle`s with `{ themeType: "light"|"dark" }`; see `surface.syncCodemirrorDarkTheme`. */
  codemirrorDark: Compartment
}

/**
 * Base CodeMirror configuration: GFM Markdown, theme tied to YABA CSS variables, compartments for growth.
 */
export function createYabaMarkdownExtensions(c: YabaEditorExtensionCompartments): Extension[] {
  return [
    c.codemirrorDark.of(EditorView.darkTheme.of(false)),
    ...YABA_EDITOR_BASIC_SETUP,
    markdown({
      base: markdownLanguage,
      codeLanguages: languages,
      extensions: yabaMarkdownMathExtensions,
      completeHTMLTags: false,
    }),
    EditorView.lineWrapping,
    syntaxHighlighting(yabaMarkdownHighlightClasses),
    markdownCodeFontFaces(),
    ...embeddedCodeFontFaces(),
    /* Theme-keyed variants: see `EditorView.darkTheme` + `surface.syncCodemirrorDarkTheme`. */
    syntaxHighlighting(yabaLightCodeHighlightStyle),
    syntaxHighlighting(yabaDarkCodeHighlightStyle),
    c.placeholder.of(placeholder("")),
    c.editable.of(EditorState.readOnly.of(false)),
    EditorView.theme({
      "&": {
        height: "100%",
        fontSize: "var(--yaba-reader-font-size, 16px)",
        lineHeight: "var(--yaba-reader-line-height, 1.6)",
      },
      ".cm-scroller": {
        color: "var(--yaba-reader-on-bg, var(--yaba-on-bg))",
        backgroundColor: "transparent",
        /* Font + padding: `editor-view.css` */
        boxSizing: "border-box",
      },
      ".cm-content": {
        caretColor: "var(--yaba-cursor, var(--yaba-primary))",
        minHeight: "100%",
      },
      ".cm-placeholder": {
        color: "var(--yaba-on-surface-variant, #888)",
      },
      ".cm-gutters": {
        backgroundColor: "transparent",
        border: "none",
        color: "var(--yaba-on-surface-variant, #888)",
      },
      "&.cm-focused .cm-cursor": {
        borderLeftColor: "var(--yaba-cursor, var(--yaba-primary))",
      },
      "&.cm-focused .cm-selectionBackground, ::selection": {
        backgroundColor: "var(--yaba-primary-container, rgba(72, 93, 146, 0.25))",
      },
    }),
    c.yabaExtras.of([]),
  ]
}
