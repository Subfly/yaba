import { createRoot } from "react-dom/client"
import { PreviewApp } from "./PreviewApp"
import { parseUrlParams, applyTheme } from "@/theme"
import "katex/dist/katex.min.css"
import "../apps/shared/global.css"
import "./preview.css"

try {
  const params = parseUrlParams()
  applyTheme(params.platform, params.appearance, params.cursorColor)
} catch (e) {
  // eslint-disable-next-line no-console
  console.error("[YABA preview] theme", e)
}

const root = document.getElementById("root")
if (root) {
  createRoot(root).render(<PreviewApp />)
}
