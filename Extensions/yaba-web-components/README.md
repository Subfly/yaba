# YABA Web Components

WebView-hosted bundles for YABA: **CodeMirror 6** Markdown note editor (GFM), **markdown preview** (`react-markdown` + GFM + sanitized HTML for Darwin link reading), **unified notemark** (`note.html`: editor + live preview + split in one `WKWebView`), plus a standalone **`dist/html-to-markdown.bundle.min.js`** (linkedom + Mozilla Readability, then unified/rehype/remark + GFM) for Darwin JavaScriptCore. Built with Vite 7, React 19 (editor + preview + note), and TypeScript.

## Build

```bash
npm install
npm run build
```

Output: `dist/editor.html`, `dist/preview.html`, `dist/note.html`, `dist/html-to-markdown.bundle.min.js`, plus JS/CSS assets. Run `npm run dev` for local development.

## Entrypoints

| File | Purpose |
|------|---------|
| `editor.html` | CodeMirror Markdown note editor (GFM) |
| `preview.html` | Saved link **Markdown** reader: `react-markdown` + `remark-gfm` + sanitized raw HTML; `YabaPreviewBridge`; `bridgeReady`: `preview` |
| `note.html` | **Darwin notemark detail** — CodeMirror + `react-markdown` preview in one document; `YabaNoteBridge`; `bridgeReady`: `note`; `setSurfaceMode(editor|preview|split)` |
| `html-to-markdown.bundle.min.js` | No HTML shell: `globalThis.HTMLToMarkdown(html, baseURL?)` → JSON `{ markdown, assets }` for Darwin JSC |

## URL parameters

Loaded by the native WebView. These apply to shells that read the shared theme helpers (`editor.html`, `preview.html`, etc.).

| Param | Required | Values | Description |
|-------|----------|--------|-------------|
| `platform` | Yes | `compose` \| `darwin` | Theme palette and font stack (`compose` is treated as Android) |
| `appearance` | No | `light` \| `dark` | Override; otherwise `prefers-color-scheme` when `auto` |
| `cursor` | No | CSS color | Caret / cursor color (e.g. folder color) |

### Example

```
editor.html?platform=compose&cursor=%23FF7C75
preview.html?platform=darwin&appearance=dark
```

## JS bridge API (native → WebView)

Hosts call these via `evaluateJavascript` / `evaluateJavaScript` on the loaded page.

### `window.YabaEditorBridge` (`editor.html`)

Markdown-first surface: `setMarkdown` / `getMarkdown`, note autosave idle, heading TOC, theme, etc. See [`src/bridge/editor-bridge.ts`](src/bridge/editor-bridge.ts).

Native apps that still call TipTap-era APIs (`setDocumentJson`, `dispatch`, in-WebView PDF export, …) must be updated separately.

### `window.YabaPreviewBridge` (`preview.html`)

Darwin link readable view: `setMarkdown`, reader theme prefs (`setReaderPreferences`, `setAppearance`, …). Markdown is rendered with `react-markdown`, `remark-gfm`, plus sanitized raw HTML. See [`src/preview/preview-bridge.ts`](src/preview/preview-bridge.ts).

### `globalThis.HTMLToMarkdown` (`html-to-markdown.bundle.min.js`)

Bundled for Darwin only (loaded via `JavaScriptCore`, not a WKWebView page). Call after evaluating the minified file; see `src/html-to-markdown/main.ts`.

**Signature:** `HTMLToMarkdown(html: string, baseURL?: string): string`

Returns a JSON string: `{ "markdown": string, "assets": [{ "assetId": string, "url": string }] }`. Markdown image destinations are rewritten to `yaba-asset://<assetId>`; `assets` maps each id to an absolute `http(s)` URL for native download (`baseURL` resolves relative paths from the article/page URL).

## Web → native (`window.YabaNativeHost.postMessage`)

Structured JSON envelopes are defined in `src/bridge/contracts/native-host.ts`, including `bridgeReady` (`feature`: `editor` \| `preview`), `shellLoad`, `toc`, `readerMetrics`, and related payloads.

**Images in WebView readers:** depending on the host, `http`/`https` and `data:` image URLs may be blocked; inline assets can use `../assets/…` with `assetsBaseUrl` like the editor, or `file:` paths from the host.

## Features (editor)

- Markdown source editing with GFM highlighting (`@codemirror/lang-markdown` + `markdownLanguage`)
- Extensibility: `yabaExtras` compartment + `EditorSurface.setYabaExtras` for custom layers
- Exports: Markdown via `exportMarkdown` / `getMarkdown` (PDF generation is native-side)

## Follow-ups

- Native app URL constants and script strings that still reference older shells (`viewer.html` / `converter.html` / `pdf-viewer.html`) may need updates to match current bundles (`editor.html`, `preview.html`) and bridges.
