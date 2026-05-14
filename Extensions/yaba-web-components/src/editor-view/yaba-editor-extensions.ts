import { syntaxHighlighting, indentUnit } from "@codemirror/language"
import { markdown, markdownLanguage } from "@codemirror/lang-markdown"
import { languages } from "@codemirror/language-data"
import { indentLess, indentMore } from "@codemirror/commands"
import { Compartment, EditorState, Prec, type Extension } from "@codemirror/state"
import { EditorView, keymap, placeholder, type Command } from "@codemirror/view"

import { markdownCodeFontFaces, embeddedCodeFontFaces } from "./editor-code-fonts"
import { YABA_EDITOR_BASIC_SETUP } from "./yaba-basic-setup"
import { yabaHighlightMark } from "./yaba-highlight-mark"
import { yabaMarkdownHighlightClasses } from "./yaba-markdown-highlight-classes"
import { yabaHighlightColorMarkExtensions } from "./yaba-highlight-color-widget"
import { yabaMarkdownMathExtensions } from "./yaba-markdown-math-extension"
import {
  yabaDarkCodeHighlightStyle,
  yabaLightCodeHighlightStyle,
} from "./yaba-code-highlight-styles"
import { yabaMacCatalystClipboardBridge } from "./catalyst-clipboard-bridge"

/** Markdown list / prose indent step (two spaces per level). */
const YABA_MARKDOWN_TAB_SIZE = 2
const YABA_MARKDOWN_INDENT_UNIT = "  "

/**
 * WKWebView on iPad and Mac Catalyst forwards Tab to accessibility focus traversal unless the event
 * is cancelled. `defaultKeymap` does not bind Tab — capture it here at top precedence.
 */
const insertFallbackIndentUnit: Command = (view) => {
  view.dispatch(view.state.replaceSelection(view.state.facet(indentUnit)))
  return true
}

const yabaTabIndent: Command = (view) => indentMore(view) || insertFallbackIndentUnit(view)

/** Always consume Shift-Tab so focus cannot escape the editor when already fully outdented. */
const yabaShiftTabIndent: Command = (view) => indentLess(view) || true

/** Notes / editor WebViews: no in-editor find — consume Mod-f / Mod-g before CM search or WKWebView find. */
const yabaNoOpCommand: Command = () => true

const yabaHighestPriorityKeymap = Prec.highest(
  keymap.of([
    {
      key: "Mod-f",
      run: yabaNoOpCommand,
      preventDefault: true,
      stopPropagation: true,
    },
    {
      key: "Mod-g",
      run: yabaNoOpCommand,
      shift: yabaNoOpCommand,
      preventDefault: true,
      stopPropagation: true,
    },
    {
      key: "Tab",
      run: yabaTabIndent,
      shift: yabaShiftTabIndent,
      preventDefault: true,
      stopPropagation: true,
    },
  ]),
)

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
    EditorState.tabSize.of(YABA_MARKDOWN_TAB_SIZE),
    indentUnit.of(YABA_MARKDOWN_INDENT_UNIT),
    yabaHighestPriorityKeymap,
    c.codemirrorDark.of(EditorView.darkTheme.of(false)),
    ...YABA_EDITOR_BASIC_SETUP,
    markdown({
      base: markdownLanguage,
      codeLanguages: languages,
      extensions: [...yabaMarkdownMathExtensions, yabaHighlightMark],
      completeHTMLTags: false,
    }),
    EditorView.lineWrapping,
    syntaxHighlighting(yabaMarkdownHighlightClasses),
    ...yabaHighlightColorMarkExtensions(),
    markdownCodeFontFaces(),
    ...embeddedCodeFontFaces(),
    /* Theme-keyed variants: see `EditorView.darkTheme` + `surface.syncCodemirrorDarkTheme`. */
    syntaxHighlighting(yabaLightCodeHighlightStyle),
    syntaxHighlighting(yabaDarkCodeHighlightStyle),
    c.placeholder.of(placeholder("")),
    c.editable.of(EditorState.readOnly.of(false)),
    yabaMacCatalystClipboardBridge(),
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
      ".cm-cursor": {
        borderLeftWidth: "2px",
        borderLeftStyle: "solid",
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
