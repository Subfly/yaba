/** Canonical inline asset path prefix persisted with notes. */
export const INLINE_ASSET_PREFIX = "../assets/"

export function rewriteAssetPathsInMarkdown(markdown: string, assetsBaseUrl: string): string {
  if (!markdown.includes(INLINE_ASSET_PREFIX)) return markdown
  const base = assetsBaseUrl.replace(/\/?$/, "/")
  return markdown.replaceAll(INLINE_ASSET_PREFIX, `${base}assets/`)
}

export function normalizeMarkdownAssetPathsForPersistence(
  markdown: string,
  lastAssetsBaseUrl: string | undefined,
): string {
  if (!lastAssetsBaseUrl || !markdown.includes("assets/")) return markdown
  const base = lastAssetsBaseUrl.replace(/\/?$/, "/")
  const absolutePrefix = `${base}assets/`
  if (!markdown.includes(absolutePrefix)) return markdown
  return markdown.replaceAll(absolutePrefix, INLINE_ASSET_PREFIX)
}

export function normalizeImageSrcForPersistence(src: string, lastAssetsBaseUrl: string | undefined): string | null {
  const s = src.trim()
  if (!s) return null
  if (s.startsWith(INLINE_ASSET_PREFIX)) return s
  if (lastAssetsBaseUrl) {
    const base = lastAssetsBaseUrl.replace(/\/?$/, "/")
    const absolutePrefix = `${base}assets/`
    if (s.startsWith(absolutePrefix)) {
      return `${INLINE_ASSET_PREFIX}${s.slice(absolutePrefix.length)}`
    }
  }
  const idx = s.indexOf("/assets/")
  if (idx >= 0) {
    const after = s.slice(idx + "/assets/".length).split("?")[0].split("#")[0]
    if (after && !after.includes("/")) {
      return `${INLINE_ASSET_PREFIX}${after}`
    }
  }
  return null
}

/** Markdown image/link patterns referencing note assets. */
export function collectUsedInlineAssetSrcsFromMarkdown(
  markdown: string,
  lastAssetsBaseUrl?: string,
): string[] {
  const out = new Set<string>()
  const imageRe = /!\[[^\]]*]\(([^)]+)\)/g
  let m: RegExpExecArray | null
  while ((m = imageRe.exec(markdown)) !== null) {
    const raw = m[1].trim().replace(/^<|>$/g, "").trim().split(/\s/)[0] ?? ""
    if (!raw) continue
    const c = normalizeImageSrcForPersistence(raw, lastAssetsBaseUrl)
    if (c) out.add(c)
    if (raw.includes(INLINE_ASSET_PREFIX)) out.add(raw.split("?")[0].split("#")[0])
  }
  return [...out].sort()
}
