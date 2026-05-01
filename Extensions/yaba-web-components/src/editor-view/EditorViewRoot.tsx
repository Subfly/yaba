import { useEffect, useRef } from "react"
import type { ViewUpdate } from "@codemirror/view"
import { mountEditorSurface, type EditorSurface } from "./surface"
import "./editor-view.css"

export function EditorViewRoot({
  onSurfaceReady,
  viewActivityRef,
}: {
  onSurfaceReady: (surface: EditorSurface) => void
  viewActivityRef?: { current: ((u: ViewUpdate) => void) | null }
}) {
  const hostRef = useRef<HTMLDivElement>(null)
  const readyRef = useRef(onSurfaceReady)
  readyRef.current = onSurfaceReady

  useEffect(() => {
    const host = hostRef.current
    if (!host) return
    return mountEditorSurface(host, (s) => readyRef.current(s), viewActivityRef)
  }, [viewActivityRef])

  return <div className="yaba-editor-container" data-yaba-editor-root ref={hostRef} />
}
