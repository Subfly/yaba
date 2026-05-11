import { useEffect, useState } from "react"
import { MarkdownPreviewBody } from "./MarkdownPreviewBody"
import { initPreviewBridge } from "./preview-bridge"

export function PreviewApp() {
  const [markdown, setMarkdown] = useState("")

  useEffect(() => {
    return initPreviewBridge({
      setMarkdownState: setMarkdown,
    })
  }, [])

  return (
    <div
      data-yaba-preview-root
      style={{
        width: "100%",
        maxWidth: "100%",
        height: "100%",
        minHeight: 0,
        minWidth: 0,
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
      }}
    >
      <div
        className="yaba-preview-scroll"
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
          <MarkdownPreviewBody markdown={markdown} />
        </div>
      </div>
    </div>
  )
}
