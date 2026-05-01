import { EditorView } from "@codemirror/view"

import type { SelectionSnapshot } from "./selection-snapshot"
export type { SelectionSnapshot } from "./selection-snapshot"

export function getSelectionSnapshotFromView(view: EditorView | null): SelectionSnapshot | null {
  if (!view) return null

  const { from, to } = view.state.selection.main
  if (from === to) return null

  const doc = view.state.doc
  const selectedText = doc.sliceString(from, to)
  if (!selectedText.trim()) return null

  const prefixLength = 30
  const suffixLength = 30
  const prefixStart = Math.max(0, from - prefixLength)
  const suffixEnd = Math.min(doc.length, to + suffixLength)
  const rawPrefix = doc.sliceString(prefixStart, from)
  const rawSuffix = doc.sliceString(to, suffixEnd)

  return {
    selectedText: selectedText.trim(),
    prefixText: rawPrefix.trim() || undefined,
    suffixText: rawSuffix.trim() || undefined,
  }
}
