import { useCallback, useRef, useState } from "react"
import type { ViewUpdate } from "@codemirror/view"
import { EditorViewRoot } from "@/editor-view/EditorViewRoot"
import type { EditorSurface } from "@/editor-view/surface"
import { MarkdownPreviewBody } from "@/preview/MarkdownPreviewBody"
import { initNoteBridge } from "./note-bridge"

export function NoteApp() {
  const [previewMarkdown, setPreviewMarkdown] = useState("")
  const viewActivityRef = useRef<((u: ViewUpdate) => void) | null>(null)

  const onSurfaceReady = useCallback((surface: EditorSurface) => {
    initNoteBridge(surface, viewActivityRef, {
      setPreviewMarkdown: setPreviewMarkdown,
    })
  }, [])

  return (
    <div
      className="yaba-note-root"
      data-yaba-note-root
      style={{
        width: "100%",
        height: "100%",
        minHeight: 0,
        minWidth: 0,
        display: "flex",
        flexDirection: "row",
        overflow: "hidden",
        backgroundColor: "transparent",
      }}
    >
      <div className="yaba-note-editor-pane">
        <div
          data-yaba-editor
          style={{ width: "100%", height: "100%", backgroundColor: "transparent" }}
        >
          <EditorViewRoot onSurfaceReady={onSurfaceReady} viewActivityRef={viewActivityRef} />
        </div>
      </div>
      <div className="yaba-note-preview-pane">
        <div
          className="yaba-preview-scroll yaba-note-preview-scroll"
          style={{
            flex: 1,
            minHeight: 0,
            minWidth: 0,
            maxWidth: "100%",
            overflowX: "hidden",
            overflowY: "auto",
            WebkitOverflowScrolling: "touch",
          }}
        >
          <div className="yaba-reader-column-wrap">
            <MarkdownPreviewBody markdown={previewMarkdown} />
          </div>
        </div>
      </div>
    </div>
  )
}
