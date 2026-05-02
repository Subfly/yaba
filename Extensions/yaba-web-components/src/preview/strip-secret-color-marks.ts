/** Removes `{#rrggbb}` secret editor marks (global regex — avoid shared `lastIndex`). */
export function stripSecretHighlightColorMarks(markdown: string): string {
  return markdown.replace(/\{\s*#([0-9a-fA-F]{6})\s*\}/g, "")
}
