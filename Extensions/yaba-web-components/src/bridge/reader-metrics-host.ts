import { postToYabaNativeHost } from "./yaba-native-host"

export function publishEpubReaderMetrics(): void {
  const win = window as Window & {
    YabaEpubBridge?: {
      isReady: () => boolean
      getCurrentPageNumber: () => number
      getPageCount: () => number
    }
  }
  const b = win.YabaEpubBridge
  if (!b?.isReady?.()) return
  postToYabaNativeHost({
    type: "readerMetrics",
    currentPage: b.getCurrentPageNumber(),
    pageCount: Math.max(1, b.getPageCount() || 1),
  })
}
