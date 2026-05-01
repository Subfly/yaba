# YABA Web Components

WebView-hosted bundles for YABA: **CodeMirror 6** Markdown note editor (GFM), **read-it-later** (static HTML reader with selection + annotations), **Excalidraw** canvas, and **EPUB.js** reader, plus a standalone **`dist/html-to-markdown.bundle.min.js`** (linkedom + Mozilla Readability, then unified/rehype/remark + GFM) for Darwin JavaScriptCore. Built with Vite 7, React 19 (editor/canvas), and TypeScript.

## Build

```bash
npm install
npm run build
```

Output: `dist/editor.html`, `dist/read-it-later.html`, `dist/canvas.html`, `dist/epub-viewer.html`, `dist/html-to-markdown.bundle.min.js`, plus JS/CSS assets. Run `npm run dev` for local development.

## Entrypoints

| File | Purpose |
|------|---------|
| `editor.html` | CodeMirror Markdown note editor (GFM) |
| `read-it-later.html` | Saved link reader: injects HTML into the DOM; selection + annotation bridge (not CodeMirror) |
| `html-to-markdown.bundle.min.js` | No HTML shell: `globalThis.HTMLToMarkdown(html, baseURL?)` → JSON `{ markdown, assets }` for Darwin JSC |
| `canvas.html` | Excalidraw canvas |
| `epub-viewer.html` | EPUB reader (epub.js) |

## URL parameters

Loaded by the native WebView. These apply to shells that read the shared theme helpers (`editor.html`, `read-it-later.html`, `epub-viewer.html`, etc.).

| Param | Required | Values | Description |
|-------|----------|--------|-------------|
| `platform` | Yes | `compose` \| `darwin` | Theme palette and font stack (`compose` is treated as Android) |
| `appearance` | No | `light` \| `dark` | Override; otherwise `prefers-color-scheme` when `auto` |
| `cursor` | No | CSS color | Caret / cursor color (e.g. folder color) |

### Example

```
editor.html?platform=compose&cursor=%23FF7C75
read-it-later.html?platform=darwin&appearance=dark
```

## JS bridge API (native → WebView)

Hosts call these via `evaluateJavascript` / `evaluateJavaScript` on the loaded page.

### `window.YabaEditorBridge` (`editor.html`)

Markdown-first surface: `setMarkdown` / `getMarkdown`, annotations, note autosave idle, heading TOC, theme, etc. See [`src/bridge/editor-bridge.ts`](src/bridge/editor-bridge.ts).

Native apps that still call TipTap-era APIs (`setDocumentJson`, `dispatch`, in-WebView PDF export, …) must be updated separately.

### `window.YabaReadItLaterBridge` (`read-it-later.html`)

Passive HTML surface: `setHtml` / `setReaderHtml` load article HTML; `setAnnotations` applies highlight colors to `span.yaba-annotation-mark` regions; selection and `applyAnnotationToSelection` / `removeAnnotationFromDocument` operate on the live DOM. Typing mirrors a subset of `YabaEditorBridge` where native still expects the same method names.

### `globalThis.HTMLToMarkdown` (`html-to-markdown.bundle.min.js`)

Bundled for Darwin only (loaded via `JavaScriptCore`, not a WKWebView page). Call after evaluating the minified file; see `src/html-to-markdown/main.ts`.

**Signature:** `HTMLToMarkdown(html: string, baseURL?: string): string`

Returns a JSON string: `{ "markdown": string, "assets": [{ "assetId": string, "url": string }] }`. Markdown image destinations are rewritten to `yaba-asset://<assetId>`; `assets` maps each id to an absolute `http(s)` URL for native download (`baseURL` resolves relative paths from the article/page URL).

### `window.YabaEpubBridge` (`epub-viewer.html`)

Unchanged EPUB reader bridge. See `src/apps/epub-viewer/epub-viewer-bridge.ts`.

## Web → native (`window.YabaNativeHost.postMessage`)

Structured JSON envelopes are defined in `src/bridge/contracts/native-host.ts`, including `bridgeReady` (`feature`: `editor` \| `read-it-later` \| `epub` \| `canvas`), `shellLoad`, `toc`, `readerMetrics`, and EPUB/Canvas-specific payloads.

**Images in read-it-later:** `http`/`https` and `data:` image URLs are not loaded; inline assets should use `../assets/…` with `assetsBaseUrl` like the editor, or `file:` paths from the host.

## Features (editor)

- Markdown source editing with GFM highlighting (`@codemirror/lang-markdown` + `markdownLanguage`)
- Extensibility: `yabaExtras` compartment + `EditorSurface.setYabaExtras` for custom layers (annotations use a separate state field today)
- Exports: Markdown via `exportMarkdown` / `getMarkdown` (PDF generation is native-side)

## Follow-ups

- Native app URL constants and script strings that still reference `viewer.html` / `converter.html` / `pdf-viewer.html` may need updates to match `read-it-later.html` and related bridges.
