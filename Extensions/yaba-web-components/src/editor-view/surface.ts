import { Compartment, EditorSelection, EditorState, type Extension } from "@codemirror/state"
import { EditorView, placeholder as cmPlaceholder, type ViewUpdate } from "@codemirror/view"
import {
  addAnnotationRange,
  annotationModel,
  getDefaultColorRoleForId,
  removeAnnotationId,
  resetAnnotationRanges,
  selectionOverlapsAnnotationRange,
  setAnnotationPaletteEffect,
  type AnnotationForRendering,
} from "./annotation-extension"
import { createYabaMarkdownExtensions } from "./yaba-editor-extensions"

export interface EditorSurface {
  readonly view: EditorView
  /** Replace document text. When `resetAnnotations` is true (default), clears in-memory annotation ranges. */
  setMarkdown(text: string, options?: { resetAnnotations?: boolean }): void
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
  scrollToAnnotation(id: string): void
  applyAnnotationToSelection(annotationId: string): boolean
  removeAnnotationFromDocument(annotationId: string): number
  setAnnotationPalette(annotations: AnnotationForRendering[]): void
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
    setMarkdown(text, options) {
      const reset = options?.resetAnnotations !== false
      view.dispatch({
        changes: { from: 0, to: view.state.doc.length, insert: text },
        ...(reset ? { effects: resetAnnotationRanges.of(true) } : {}),
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
    scrollToAnnotation(id) {
      const ranges = view.state.field(annotationModel).ranges
      const target = ranges.find((r) => r.id === id)
      if (!target) return
      view.dispatch({
        selection: EditorSelection.create([EditorSelection.range(target.from, target.to)]),
        scrollIntoView: true,
      })
    },
    applyAnnotationToSelection(annotationId) {
      const main = view.state.selection.main
      if (main.empty) return false
      const model = view.state.field(annotationModel)
      if (selectionOverlapsAnnotationRange(model.ranges, main.from, main.to)) return false
      const role = getDefaultColorRoleForId(model, annotationId)
      view.dispatch({
        effects: addAnnotationRange.of({
          id: annotationId,
          from: Math.min(main.from, main.to),
          to: Math.max(main.from, main.to),
          colorRole: role,
        }),
      })
      return true
    },
    removeAnnotationFromDocument(annotationId) {
      const before = view.state.field(annotationModel).ranges.filter((r) => r.id === annotationId).length
      view.dispatch({
        effects: removeAnnotationId.of(annotationId),
      })
      return before
    },
    setAnnotationPalette(annotations) {
      view.dispatch({
        effects: setAnnotationPaletteEffect.of(annotations),
      })
    },
  }

  onReady(surface)
  return () => view.destroy()
}
