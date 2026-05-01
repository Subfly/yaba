export interface EditorFormattingState {
  headingLevel: number
  bold: boolean
  italic: boolean
  underline: boolean
  strikethrough: boolean
  subscript: boolean
  superscript: boolean
  code: boolean
  codeBlock: boolean
  blockquote: boolean
  bulletList: boolean
  orderedList: boolean
  taskList: boolean
  canUndo: boolean
  canRedo: boolean
  canIndent: boolean
  canOutdent: boolean
  inTable: boolean
  canAddRowBefore: boolean
  canAddRowAfter: boolean
  canDeleteRow: boolean
  canAddColumnBefore: boolean
  canAddColumnAfter: boolean
  canDeleteColumn: boolean
  inlineMath: boolean
  blockMath: boolean
  textHighlight: boolean
}

export function getEmptyFormattingState(): EditorFormattingState {
  return {
    headingLevel: 0,
    bold: false,
    italic: false,
    underline: false,
    strikethrough: false,
    subscript: false,
    superscript: false,
    code: false,
    codeBlock: false,
    blockquote: false,
    bulletList: false,
    orderedList: false,
    taskList: false,
    canUndo: false,
    canRedo: false,
    canIndent: false,
    canOutdent: false,
    inTable: false,
    canAddRowBefore: false,
    canAddRowAfter: false,
    canDeleteRow: false,
    canAddColumnBefore: false,
    canAddColumnAfter: false,
    canDeleteColumn: false,
    inlineMath: false,
    blockMath: false,
    textHighlight: false,
  }
}

/**
 * Markdown/CodeMirror editor: native toolbar state is not yet derived from syntax;
 * publish empty formatting until dedicated toggle support lands.
 */
export function getActiveFormattingState(): EditorFormattingState {
  return getEmptyFormattingState()
}

export function getActiveFormattingJson(): string {
  return JSON.stringify(getActiveFormattingState())
}
