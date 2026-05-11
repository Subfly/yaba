import { createRoot } from "react-dom/client"
import { NoteApp } from "./NoteApp"
import { parseUrlParams, applyTheme } from "@/theme"
import "katex/dist/katex.min.css"
import "../apps/shared/global.css"
import "../preview/preview.css"
import "../editor-view/editor-view.css"
import "./note.css"

try {
  const params = parseUrlParams()
  applyTheme(params.platform, params.appearance, params.cursorColor)
} catch (e) {
  // eslint-disable-next-line no-console
  console.error("[YABA note] theme", e)
}

document.documentElement.dataset.yabaNoteSurfaceMode = document.documentElement.dataset.yabaNoteSurfaceMode ?? "editor"

const root = document.getElementById("root")
if (root) {
  createRoot(root).render(<NoteApp />)
}
