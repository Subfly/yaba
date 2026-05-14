import { useEffect, useMemo, useRef, useState } from "react"
import type { CSSProperties, KeyboardEvent, MouseEvent, ReactNode } from "react"
import ReactMarkdown, { defaultUrlTransform } from "react-markdown"
import remarkBreaks from "remark-breaks"
import remarkGfm from "remark-gfm"
import remarkMath from "remark-math"
import type { SyntaxHighlighterProps } from "react-syntax-highlighter"
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter"
import { oneDark, oneLight } from "react-syntax-highlighter/dist/esm/styles/prism"
import rehypeKatex from "rehype-katex"
import rehypeRaw from "rehype-raw"
import type { Components } from "react-markdown"
import { postToYabaNativeHost } from "@/bridge/yaba-native-host"
import { previewImageSrc, previewUrlTransformForLinks } from "./preview-asset-url"
import {
  prepareMarkdownForPreview,
  type PreviewTaskToggleRegion,
} from "./preview-markdown-prepare"
import { previewRehypeSanitizePlugin } from "./preview-sanitize"
import { stripSecretHighlightColorMarks } from "./strip-secret-color-marks"
import { YABA_READER_THEME_ATTR, type ReaderThemeName } from "@/theme/reader-document-vars"

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

function readDocumentReaderTheme(): ReaderThemeName {
  const raw = document.documentElement.getAttribute(YABA_READER_THEME_ATTR)
  if (raw === "dark" || raw === "light" || raw === "sepia" || raw === "system") return raw
  return "system"
}

/** Tracks `applyReaderThemeCssVars` — Prism/code chrome need sepia-tinted surfaces (Darwin paper parity). */
function useYabaReaderTheme(): ReaderThemeName {
  const [theme, setTheme] = useState<ReaderThemeName>(() =>
    typeof document === "undefined" ? "system" : readDocumentReaderTheme(),
  )

  useEffect(() => {
    setTheme(readDocumentReaderTheme())
    const observer = new MutationObserver(() => setTheme(readDocumentReaderTheme()))
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: [YABA_READER_THEME_ATTR],
    })
    return () => observer.disconnect()
  }, [])

  return theme
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

function readDataNum(props: Record<string, unknown>, key: string): number | undefined {
  const v = props[key]
  if (typeof v === "number" && Number.isFinite(v)) return v
  if (typeof v === "string") {
    const n = Number(v)
    return Number.isFinite(n) ? n : undefined
  }
  return undefined
}

/** rehype/hast + React may expose `data-*` as hyphenated or camelCase on components. */
function readDataNumFirst(props: Record<string, unknown>, keys: readonly string[]): number | undefined {
  for (const key of keys) {
    const n = readDataNum(props, key)
    if (n !== undefined) return n
  }
  return undefined
}

function postPreviewHighlightTap(props: Record<string, unknown>): void {
  const syntaxStart = readDataNumFirst(props, ["data-yaba-syntax-start", "dataYabaSyntaxStart"])
  const syntaxEnd = readDataNumFirst(props, ["data-yaba-syntax-end", "dataYabaSyntaxEnd"])
  const innerStart = readDataNumFirst(props, ["data-yaba-inner-start", "dataYabaInnerStart"])
  const innerEnd = readDataNumFirst(props, ["data-yaba-inner-end", "dataYabaInnerEnd"])
  const hexRaw = props["data-yaba-hex"] ?? props["dataYabaHex"]
  const hex =
    typeof hexRaw === "string" ? hexRaw.trim().toLowerCase().replace(/^#/, "") : ""
  if (
    syntaxStart === undefined ||
    syntaxEnd === undefined ||
    innerStart === undefined ||
    innerEnd === undefined ||
    syntaxEnd < syntaxStart ||
    innerEnd < innerStart
  ) {
    return
  }
  postToYabaNativeHost({
    type: "previewHighlightMarkTap",
    syntaxStart,
    syntaxEnd,
    innerStart,
    innerEnd,
    hex: hex.length === 6 ? hex : "",
  })
}

function buildMarkdownComponents(
  headingCounter: { current: number },
  prismTheme: PrismHighlightStyle,
  taskRegions: PreviewTaskToggleRegion[],
  readerTheme: ReaderThemeName,
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
    ...(readerTheme === "sepia"
      ? {
          background: "color-mix(in srgb, var(--yaba-reader-on-bg) 10%, var(--yaba-reader-bg))",
        }
      : {}),
  }

  const taskCheckboxIndex = { current: 0 }
  taskCheckboxIndex.current = 0

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
    input: ({ type, disabled: _disabled, ...rest }) => {
      if (type === "checkbox") {
        const idx = taskCheckboxIndex.current++
        const region = taskRegions[idx]
        return (
          <input
            {...rest}
            type="checkbox"
            disabled={false}
            readOnly
            className={`yaba-preview-task-checkbox ${normalizeClassName(rest.className)}`.trim()}
            onClick={(e: MouseEvent<HTMLInputElement>) => {
              e.preventDefault()
              if (!region) return
              postToYabaNativeHost({
                type: "previewTaskCheckboxTap",
                bracketOpen: region.bracketOpen,
              })
            }}
          />
        )
      }
      return <input type={type} {...rest} />
    },
    mark: ({ children, ...props }) => {
      const rec = props as Record<string, unknown>
      const hasMeta =
        readDataNumFirst(rec, ["data-yaba-syntax-start", "dataYabaSyntaxStart"]) !== undefined
      if (hasMeta) {
        const fire = (): void => postPreviewHighlightTap(rec)
        return (
          <mark
            {...props}
            onClick={(e: MouseEvent<HTMLElement>) => {
              e.preventDefault()
              fire()
            }}
            onKeyDown={(e: KeyboardEvent<HTMLElement>) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault()
                fire()
              }
            }}
          >
            {children}
          </mark>
        )
      }
      return <mark {...props}>{children}</mark>
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
  const readerTheme = useYabaReaderTheme()

  const prepared = useMemo(() => prepareMarkdownForPreview(markdown ?? ""), [markdown])
  const components = useMemo(
    () => buildMarkdownComponents(headingCounter, prismTheme, prepared.taskRegions, readerTheme),
    [prismTheme, prepared.taskRegions, readerTheme],
  )

  const source = stripSecretHighlightColorMarks(prepared.markdown)

  return (
    <div className="yaba-markdown-preview">
      <ReactMarkdown
        remarkPlugins={[remarkGfm, remarkMath, remarkBreaks]}
        rehypePlugins={[rehypeRaw, rehypeKatex, previewRehypeSanitizePlugin]}
        urlTransform={(url) => previewUrlTransformForLinks(url, defaultUrlTransform)}
        components={components}
      >
        {source}
      </ReactMarkdown>
    </div>
  )
}
