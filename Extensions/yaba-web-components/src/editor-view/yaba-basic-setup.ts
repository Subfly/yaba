/**
 * Same extensions as codemirror `basicSetup`, but **without**
 * `syntaxHighlighting(defaultHighlightStyle, { fallback: true })`.
 *
 * Reason: fallback highlighters are ignored whenever any non-fallback
 * `syntaxHighlighting` facet is registered. Our markdown/fonts use the main
 * facet, which would mute `defaultHighlightStyle` everywhere (including fenced
 * JS/Python). We add `syntaxHighlighting(yabaLightCodeHighlightStyle)` and
 * `syntaxHighlighting(yabaDarkCodeHighlightStyle)` (non-fallback) in
 * `yaba-editor-extensions.ts`, keyed via `EditorView.darkTheme`.
 */
import { closeBrackets, autocompletion, closeBracketsKeymap, completionKeymap } from "@codemirror/autocomplete"
import { defaultKeymap, history, historyKeymap, insertBlankLine } from "@codemirror/commands"
import { bracketMatching, foldGutter, foldKeymap, indentOnInput } from "@codemirror/language"
import { lintKeymap } from "@codemirror/lint"
import { highlightSelectionMatches, searchKeymap } from "@codemirror/search"
import type { Extension } from "@codemirror/state"
import { EditorState } from "@codemirror/state"
import {
  crosshairCursor,
  drawSelection,
  dropCursor,
  highlightActiveLine,
  highlightActiveLineGutter,
  highlightSpecialChars,
  keymap,
  lineNumbers,
  rectangularSelection,
} from "@codemirror/view"

export const YABA_EDITOR_BASIC_SETUP: Extension[] = [
  lineNumbers(),
  highlightActiveLineGutter(),
  highlightSpecialChars(),
  history(),
  foldGutter(),
  drawSelection(),
  dropCursor(),
  EditorState.allowMultipleSelections.of(true),
  indentOnInput(),
  bracketMatching(),
  closeBrackets(),
  autocompletion(),
  rectangularSelection(),
  crosshairCursor(),
  highlightActiveLine(),
  highlightSelectionMatches(),
  keymap.of([
    { key: "Enter", run: insertBlankLine },
    ...closeBracketsKeymap,
    ...defaultKeymap,
    ...searchKeymap,
    ...historyKeymap,
    ...foldKeymap,
    ...completionKeymap,
    ...lintKeymap,
  ]),
]
