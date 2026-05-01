import { useCallback, useRef } from "react"
import type { ViewUpdate } from "@codemirror/view"
import { EditorViewRoot } from "@/editor-view/EditorViewRoot"
import type { EditorSurface } from "@/editor-view/surface"
import { initEditorBridge } from "@/bridge/editor-bridge"

function EditorApp() {
  const viewActivityRef = useRef<((u: ViewUpdate) => void) | null>(null)

  const onSurfaceReady = useCallback((surface: EditorSurface) => {
    initEditorBridge(surface, viewActivityRef)
  }, [])

  return (
    <div
      data-yaba-editor
      style={{ width: "100%", height: "100%", backgroundColor: "transparent" }}
    >
      <EditorViewRoot onSurfaceReady={onSurfaceReady} viewActivityRef={viewActivityRef} />
    </div>
  )
}

export { EditorApp }
