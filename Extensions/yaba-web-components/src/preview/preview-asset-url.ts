/**
 * Resolve Markdown image destinations to a WKWebView scheme URL native can serve.
 * Supports bare asset IDs, yaba-asset://, and legacy ../assets/<id>.<ext> paths.
 */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function stripQueryHash(s: string): string {
  return s.split("?")[0]?.split("#")[0] ?? s
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

  if (/^https?:\/\//i.test(first) || first.startsWith("data:") || first.startsWith("blob:")) {
    return undefined
  }

  if (first.startsWith("yaba-asset:")) {
    return first
  }

  if (first.includes("../assets/")) {
    const tail = stripQueryHash(first.replace(/^.*\.\.\/assets\//, ""))
    const id = tail.replace(/\.[^.]+$/, "")
    if (id && !id.includes("/")) return `yaba-asset://${id}`
    return undefined
  }

  if (first.startsWith("yaba-asset://")) {
    return first
  }

  if (looksLikeBareAssetId(first)) {
    const id = stripQueryHash(first).replace(/\.[^.]+$/, "")
    return `yaba-asset://${id}`
  }

  return undefined
}

export function previewUrlTransformForLinks(value: string, defaultTransform: (v: string) => string): string {
  const v = value.trim()
  if (v.startsWith("yaba-asset:") || v.startsWith("yaba-asset://")) {
    return v
  }
  return defaultTransform(v)
}
