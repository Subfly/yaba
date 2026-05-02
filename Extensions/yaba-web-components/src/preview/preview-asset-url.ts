/**
 * Resolve Markdown / raw HTML image destinations for WKWebView preview.
 * - `https?://`, protocol-relative `//`, `data:`, `blob:` pass through for normal loading.
 * - `yaba-asset://` and `../assets/…` map to the native scheme handler (SwiftData-backed bytes).
 */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function stripQueryHash(s: string): string {
  return s.split("?")[0]?.split("#")[0] ?? s
}

function decodeURIComponentSafe(s: string): string {
  try {
    return decodeURIComponent(s)
  } catch {
    return s
  }
}

/**
 * Extract `<id>` from any URL/path ending with `/assets/<id>.<ext>`.
 * Supports canonical `../assets/...` and absolute URLs rewritten by editor bridges.
 * TODO: REMOVE
 */
function assetIdFromAssetsPath(raw: string): string | undefined {
  const cleaned = stripQueryHash(raw.trim())
  const idx = cleaned.lastIndexOf("/assets/")
  if (idx < 0) return undefined
  const tail = cleaned.slice(idx + "/assets/".length)
  if (!tail || tail.includes("/")) return undefined
  const id = decodeURIComponentSafe(tail).replace(/\.[^.]+$/, "").trim()
  if (!id || id.includes("/")) return undefined
  return id
}

/** True if the string looks like a stored inline asset id (not a URL path). */
function looksLikeBareAssetId(s: string): boolean {
  const t = stripQueryHash(s).trim()
  if (!t || t.includes("/") || t.includes(":")) return false
  if (UUID_RE.test(t)) return true
  // Allow alphanumeric ids (e.g. Room / custom ids)
  return /^[A-Za-z0-9_-]{8,128}$/.test(t)
}

export function previewImageSrc(raw: string | undefined): string | undefined {
  if (raw == null) return undefined
  const first = raw.trim().replace(/^<|>$/g, "").trim().split(/\s/)[0] ?? ""
  if (!first) return undefined

  if (/^https?:\/\//i.test(first)) {
    return first
  }
  if (first.startsWith("//") && first.length > 2) {
    return `https:${first}`
  }
  if (first.startsWith("data:") || first.startsWith("blob:")) {
    return first
  }

  if (first.startsWith("yaba-asset://") || first.startsWith("yaba-asset:")) {
    return first
  }

  const assetsPathId = assetIdFromAssetsPath(first)
  if (assetsPathId) {
    // Use a path-based URL form to avoid host parsing ambiguities.
    return `yaba-asset:///${encodeURIComponent(assetsPathId)}`
  }

  if (looksLikeBareAssetId(first)) {
    const id = stripQueryHash(first).replace(/\.[^.]+$/, "")
    return `yaba-asset:///${encodeURIComponent(id)}`
  }

  return undefined
}

export function previewUrlTransformForLinks(value: string, defaultTransform: (v: string) => string): string {
  const v = value.trim()
  if (v.startsWith("yaba-asset:") || v.startsWith("yaba-asset://")) {
    return v
  }
  if (v.startsWith("yaba-mention:") || v.startsWith("yaba-mention://")) {
    return v
  }
  return defaultTransform(v)
}
