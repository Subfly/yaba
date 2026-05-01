import { Compartment, EditorSelection, EditorState, type Extension } from "@codemirror/state"
import { EditorView, placeholder as cmPlaceholder, type ViewUpdate } from "@codemirror/view"
import { createYabaMarkdownExtensions } from "./yaba-editor-extensions"

export interface EditorSurface {
  readonly view: EditorView
  setMarkdown(text: string): void
  getMarkdown(): string
  setEditable(editable: boolean): void
  setPlaceholder(text: string): void
  /**
   * Replace the `yabaExtras` compartment — intended for YABA-specific layers (custom parses, widgets, previews).
   */
  setYabaExtras(extra: Extension): void
  focus(): void
  blur(): void
  scrollPosIntoView(pos: number): void
}

export function mountEditorSurface(
  parent: HTMLElement,
  onReady: (surface: EditorSurface) => void,
  viewActivityRef?: { current: ((u: ViewUpdate) => void) | null },
): () => void {
  const placeholderC = new Compartment()
  const editableC = new Compartment()
  const yabaExtrasC = new Compartment()

  const state = EditorState.create({
    doc: "",
    extensions: [
      ...createYabaMarkdownExtensions({
        placeholder: placeholderC,
        editable: editableC,
        yabaExtras: yabaExtrasC,
      }),
      ...(viewActivityRef
        ? [
            EditorView.updateListener.of((u) => {
              viewActivityRef.current?.(u)
            }),
          ]
        : []),
    ],
  })

  const view = new EditorView({ state, parent })

  const surface: EditorSurface = {
    view,
    setMarkdown(text) {
      view.dispatch({
        changes: { from: 0, to: view.state.doc.length, insert: text },
      })
    },
    getMarkdown() {
      return view.state.doc.toString()
    },
    setEditable(editable) {
      view.dispatch({
        effects: editableC.reconfigure(EditorState.readOnly.of(!editable)),
      })
    },
    setPlaceholder(text) {
      view.dispatch({
        effects: placeholderC.reconfigure(cmPlaceholder(text)),
      })
    },
    setYabaExtras(extra) {
      view.dispatch({
        effects: yabaExtrasC.reconfigure(extra),
      })
    },
    focus() {
      view.focus()
    },
    blur() {
      view.contentDOM.blur()
    },
    scrollPosIntoView(pos) {
      view.dispatch({
        selection: EditorSelection.cursor(pos),
        scrollIntoView: true,
      })
    },
  }

  onReady(surface)
  return () => view.destroy()
}
