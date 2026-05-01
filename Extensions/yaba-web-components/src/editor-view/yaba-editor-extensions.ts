import { defaultHighlightStyle, syntaxHighlighting } from "@codemirror/language"
import { markdown, markdownLanguage } from "@codemirror/lang-markdown"
import { languages } from "@codemirror/language-data"
import { Compartment, EditorState, type Extension } from "@codemirror/state"
import { EditorView, placeholder } from "@codemirror/view"
import { basicSetup } from "codemirror"
import { annotationExtensions } from "./annotation-extension"

export interface YabaEditorExtensionCompartments {
  placeholder: Compartment
  editable: Compartment
  /** Hook point for custom parsing, widgets, previews, and future YABA layers. */
  yabaExtras: Compartment
}

/**
 * Base CodeMirror configuration: GFM Markdown, theme tied to YABA CSS variables, compartments for growth.
 */
export function createYabaMarkdownExtensions(c: YabaEditorExtensionCompartments): Extension[] {
  return [
    basicSetup,
    markdown({ base: markdownLanguage, codeLanguages: languages }),
    EditorView.lineWrapping,
    syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
    c.placeholder.of(placeholder("")),
    c.editable.of(EditorState.readOnly.of(false)),
    EditorView.theme({
      "&": {
        height: "100%",
        fontSize: "var(--yaba-reader-font-size, 18px)",
        lineHeight: "var(--yaba-reader-line-height, 1.6)",
      },
      ".cm-scroller": {
        fontFamily: "var(--yaba-font-family, inherit)",
        color: "var(--yaba-reader-on-bg, var(--yaba-on-bg))",
        backgroundColor: "transparent",
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
    ...annotationExtensions,
    c.yabaExtras.of([]),
  ]
}
