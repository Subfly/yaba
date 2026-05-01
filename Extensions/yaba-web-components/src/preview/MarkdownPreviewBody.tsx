import { useRef } from "react"
import type { ReactNode } from "react"
import ReactMarkdown, { defaultUrlTransform } from "react-markdown"
import remarkGfm from "remark-gfm"
import rehypeRaw from "rehype-raw"
import type { Components } from "react-markdown"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"
import { previewImageSrc, previewUrlTransformForLinks } from "./preview-asset-url"
import { previewRehypeSanitizePlugin } from "./preview-sanitize"

function linkLabel(children: ReactNode): string {
  if (typeof children === "string") return children
  if (Array.isArray(children)) {
    return children
      .map((c) => (typeof c === "string" ? c : typeof c === "number" ? String(c) : ""))
      .join("")
      .trim()
  }
  return ""
}

function buildMarkdownComponents(headingCounter: { current: number }): Components {
  headingCounter.current = 0
  const nextHeadingId = (): string => {
    const i = headingCounter.current
    headingCounter.current += 1
    return `toc-h-${i}`
  }

  return {
    img: ({ src, alt, ...rest }) => {
      const resolved = previewImageSrc(typeof src === "string" ? src : undefined)
      if (!resolved) {
        return (
          <span
            className="yaba-preview-blocked-image"
            data-yaba-blocked="remote-or-invalid"
            role="img"
            aria-label={typeof alt === "string" ? alt : "blocked image"}
          />
        )
      }
      // eslint-disable-next-line jsx-a11y/alt-text -- alt comes from Markdown
      return <img src={resolved} alt={typeof alt === "string" ? alt : ""} {...rest} decoding="async" />
    },
    a: ({ href, children, ...rest }) => (
      <a
        {...rest}
        href={href ?? "#"}
        onClick={(e) => {
          e.preventDefault()
          if (!href) return
          postToYabaNativeHost({
            type: "inlineLinkTap",
            pos: 0,
            text: linkLabel(children),
            url: href,
          })
        }}
      >
        {children}
      </a>
    ),
    h1: ({ children, ...p }) => (
      <h1 id={nextHeadingId()} {...p}>
        {children}
      </h1>
    ),
    h2: ({ children, ...p }) => (
      <h2 id={nextHeadingId()} {...p}>
        {children}
      </h2>
    ),
    h3: ({ children, ...p }) => (
      <h3 id={nextHeadingId()} {...p}>
        {children}
      </h3>
    ),
    h4: ({ children, ...p }) => (
      <h4 id={nextHeadingId()} {...p}>
        {children}
      </h4>
    ),
    h5: ({ children, ...p }) => (
      <h5 id={nextHeadingId()} {...p}>
        {children}
      </h5>
    ),
    h6: ({ children, ...p }) => (
      <h6 id={nextHeadingId()} {...p}>
        {children}
      </h6>
    ),
    table: ({ children, ...props }) => (
      <div className="yaba-table-wrap" role="region" aria-label="Table">
        <table {...props}>{children}</table>
      </div>
    ),
  }
}

export function MarkdownPreviewBody({ markdown }: { markdown: string }) {
  const headingCounter = useRef(0)
  headingCounter.current = 0
  const components = buildMarkdownComponents(headingCounter)

  return (
    <div className="yaba-markdown-preview">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeRaw, previewRehypeSanitizePlugin]}
        urlTransform={(url) => previewUrlTransformForLinks(url, defaultUrlTransform)}
        components={components}
      >
        {markdown}
      </ReactMarkdown>
    </div>
  )
}
