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

/** Sanitize raw HTML embedded in Markdown; allow yaba-asset for saved inline assets. */
export const previewSanitizeSchema: Options = {
  ...defaultSchema,
  protocols: mergeProtocols(defaultSchema.protocols ?? {}, {
    href: ["http", "https", "mailto", "tel", "yaba-asset"],
    src: ["http", "https", "yaba-asset"],
    cite: ["http", "https"],
  }),
}

export const previewRehypeSanitizePlugin: [typeof rehypeSanitize, Options] = [
  rehypeSanitize,
  previewSanitizeSchema,
]
