import { useEffect, useRef, useState } from "react"
import type { CSSProperties, ReactNode } from "react"
import ReactMarkdown, { defaultUrlTransform } from "react-markdown"
import remarkGfm from "remark-gfm"
import { remarkMark } from "remark-mark-highlight"
import remarkMath from "remark-math"
import type { SyntaxHighlighterProps } from "react-syntax-highlighter"
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter"
import { oneDark, oneLight } from "react-syntax-highlighter/dist/esm/styles/prism"
import rehypeKatex from "rehype-katex"
import rehypeRaw from "rehype-raw"
import type { Components } from "react-markdown"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"
import { previewImageSrc, previewUrlTransformForLinks } from "./preview-asset-url"
import { previewRehypeSanitizePlugin } from "./preview-sanitize"

function normalizeClassName(className: unknown): string {
  if (className == null) return ""
  if (typeof className === "string") return className
  if (Array.isArray(className)) return className.filter((c): c is string => typeof c === "string").join(" ")
  return ""
}

type PrismHighlightStyle = NonNullable<SyntaxHighlighterProps["style"]>

/** Tracks light/dark from document `colorScheme` (set by preview theme) plus system fallback. */
function usePreviewPrismTheme(): PrismHighlightStyle {
  const readScheme = (): "light" | "dark" => {
    if (typeof document === "undefined") return "light"
    const cs = document.documentElement.style.colorScheme.trim().toLowerCase()
    if (cs === "dark" || cs === "light") return cs
    if (typeof window.matchMedia !== "function") return "light"
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  const [scheme, setScheme] = useState<"light" | "dark">(readScheme)

  useEffect(() => {
    setScheme(readScheme())
    const onSchemeMaybeChanged = (): void => setScheme(readScheme())

    const observer = new MutationObserver(onSchemeMaybeChanged)
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["style"],
    })

    const mq =
      typeof window.matchMedia === "function" ? window.matchMedia("(prefers-color-scheme: dark)") : null
    mq?.addEventListener?.("change", onSchemeMaybeChanged)

    return () => {
      observer.disconnect()
      mq?.removeEventListener?.("change", onSchemeMaybeChanged)
    }
  }, [])

  return scheme === "dark" ? oneDark : oneLight
}

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

function buildMarkdownComponents(
  headingCounter: { current: number },
  prismTheme: PrismHighlightStyle,
): Components {
  headingCounter.current = 0
  const nextHeadingId = (): string => {
    const i = headingCounter.current
    headingCounter.current += 1
    return `toc-h-${i}`
  }

  const hlCustomStyle: CSSProperties = {
    margin: 0,
    padding: "0.6em 0.75em",
    borderRadius: 8,
    fontSize: "0.92em",
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
    /** Avoid nested block containers (`<pre><div class="syntax">…`). */
    pre: ({ children }) => children,
    code: ({ className, children }) => {
      const cls = normalizeClassName(className)
      const match = /language-(\w+)/.exec(cls)
      if (!match || match[1] === "math") {
        return <code className={cls}>{children}</code>
      }

      const codeText = String(children).replace(/\n$/, "")
      return (
        <SyntaxHighlighter
          className="yaba-syntax-highlighter"
          PreTag="div"
          language={match[1]}
          style={prismTheme}
          codeTagProps={{ className: "yaba-syntax-highlighter-inner" }}
          customStyle={hlCustomStyle}
        >
          {codeText}
        </SyntaxHighlighter>
      )
    },
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
  const prismTheme = usePreviewPrismTheme()
  const components = buildMarkdownComponents(headingCounter, prismTheme)

  return (
    <div className="yaba-markdown-preview">
      <ReactMarkdown
        remarkPlugins={[remarkGfm, remarkMark, remarkMath]}
        rehypePlugins={[rehypeRaw, rehypeKatex, previewRehypeSanitizePlugin]}
        urlTransform={(url) => previewUrlTransformForLinks(url, defaultUrlTransform)}
        components={components}
      >
        {markdown ?? ""}
      </ReactMarkdown>
    </div>
  )
}
