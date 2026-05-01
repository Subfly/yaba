import { getActiveFormattingState } from "./editor-formatting"
import { postToYabaNativeHost } from "./yaba-native-host"

let lastPublishedEditorStateJson: string | null = null

export function resetPublishedEditorHostState(): void {
  lastPublishedEditorStateJson = null
}

export function publishEditorHostState(): void {
  const formatting = getActiveFormattingState()
  const payload = {
    type: "readerMetrics" as const,
    currentPage: 1,
    pageCount: 1,
    formatting,
  }
  const json = JSON.stringify(payload)
  if (json === lastPublishedEditorStateJson) return
  lastPublishedEditorStateJson = json
  postToYabaNativeHost(payload)
}
