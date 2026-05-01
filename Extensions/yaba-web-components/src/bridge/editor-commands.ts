/**
 * Legacy shape for native rich-text command bridges.
 * TipTap/ProseMirror commands were removed; read-it-later and future hosts may still type `dispatch` against this.
 */
export type EditorCommandPayload = {
  type: string
} & Record<string, unknown>
