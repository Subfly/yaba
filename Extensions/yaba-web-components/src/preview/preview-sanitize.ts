import rehypeSanitize, { defaultSchema, type Options } from "rehype-sanitize"

function mergeProtocols(
  base: NonNullable<Options["protocols"]> | undefined,
  extra: Record<string, string[]>,
): NonNullable<Options["protocols"]> {
  const out: NonNullable<Options["protocols"]> = { ...base }
  for (const [k, v] of Object.entries(extra)) {
    const prev = out[k] ?? []
    out[k] = [...new Set([...prev, ...v])]
  }
  return out
}

/** Node names produced by KaTeX (often includes SVG glyphs and styled spans). */
const katexTagNames = [
  "svg",
  "path",
  "line",
  "polyline",
  "polygon",
  "rect",
  "circle",
  "ellipse",
  "g",
  "defs",
  "clipPath",
  "linearGradient",
  "radialGradient",
  "stop",
  "mask",
  "use",
  "foreignObject",
] as const

const commonSvgMarkup = ["className", "style"] as const

/** Sanitize raw HTML embedded in Markdown; allow yaba-asset for saved inline assets and KaTeX output. */
export const previewSanitizeSchema: Options = {
  ...defaultSchema,
  protocols: mergeProtocols(defaultSchema.protocols ?? {}, {
    href: ["http", "https", "mailto", "tel", "yaba-asset"],
    src: ["http", "https", "yaba-asset"],
    cite: ["http", "https"],
  }),
  tagNames: [...new Set([...(defaultSchema.tagNames ?? []), ...katexTagNames, "mark"])],
  attributes: {
    ...defaultSchema.attributes,
    span: [...(defaultSchema.attributes?.span ?? []), "className", "style"],
    svg: [
      ...(defaultSchema.attributes?.svg ?? []),
      ...commonSvgMarkup,
      "xmlns",
      "xmlnsXlink",
      "viewBox",
      "preserveAspectRatio",
      "width",
      "height",
      "focusable",
      "role",
      "ariaHidden",
      "fill",
      "stroke",
      "strokeOpacity",
      "fillOpacity",
    ],
    path: [...(defaultSchema.attributes?.path ?? []), ...commonSvgMarkup, "d", "fill", "stroke", "strokeWidth", "strokeLinecap", "strokeLinejoin"],
    line: [...(defaultSchema.attributes?.line ?? []), ...commonSvgMarkup, "x1", "y1", "x2", "y2", "stroke", "strokeWidth"],
    polyline: [...(defaultSchema.attributes?.polyline ?? []), ...commonSvgMarkup, "points", "fill", "stroke", "strokeWidth"],
    polygon: [...(defaultSchema.attributes?.polygon ?? []), ...commonSvgMarkup, "points", "fill", "stroke", "strokeWidth"],
    rect: [...(defaultSchema.attributes?.rect ?? []), ...commonSvgMarkup, "x", "y", "width", "height", "rx", "ry", "fill", "stroke", "strokeWidth"],
    circle: [...(defaultSchema.attributes?.circle ?? []), ...commonSvgMarkup, "cx", "cy", "r", "fill", "stroke"],
    ellipse: [...(defaultSchema.attributes?.ellipse ?? []), ...commonSvgMarkup, "cx", "cy", "rx", "ry", "fill", "stroke"],
    g: [...(defaultSchema.attributes?.g ?? []), ...commonSvgMarkup, "stroke", "strokeWidth", "strokeLinecap", "strokeLinejoin", "transform"],
    defs: [...(defaultSchema.attributes?.defs ?? [])],
    clipPath: [...(defaultSchema.attributes?.clipPath ?? []), "clipPathUnits", "id"],
    linearGradient: [...(defaultSchema.attributes?.linearGradient ?? []), ...commonSvgMarkup, "id", "x1", "y1", "x2", "y2", "gradientUnits"],
    radialGradient: [...(defaultSchema.attributes?.radialGradient ?? []), ...commonSvgMarkup, "id", "cx", "cy", "r", "gradientUnits"],
    stop: [...(defaultSchema.attributes?.stop ?? []), ...commonSvgMarkup, "offset", "stopColor", "stopOpacity"],
    mask: [...(defaultSchema.attributes?.mask ?? []), ...commonSvgMarkup, "id", "maskContentUnits"],
    use: [...(defaultSchema.attributes?.use ?? []), ...commonSvgMarkup, "href", "x", "y", "width", "height", "xlinkHref"],
    foreignObject: [...(defaultSchema.attributes?.foreignObject ?? []), ...commonSvgMarkup],
  },
}

export const previewRehypeSanitizePlugin: [typeof rehypeSanitize, Options] = [
  rehypeSanitize,
  previewSanitizeSchema,
]
