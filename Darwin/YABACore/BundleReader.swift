//
//  BundleReader.swift
//  YABACore
//
//  Resolves bundled files by **resource name**. Icons/metadata use a flat lookup at bundle root.
//  Web shells and their `chunks/` / `assets/` live under `WebComponents/` (see `webComponentURL`).
//
//  Web components layout matches `Extensions/yaba-web-components` Vite output: `editor.html` (CodeMirror
//  Markdown / `YabaEditorBridge`), `preview.html` (Markdown preview / `YabaPreviewBridge`),
//  `canvas.html`, `read-it-later.html`, optional `epub-viewer.html`, plus `html-to-markdown.bundle.min.js` for JavaScriptCore (no WKWebView shell).
//

import Foundation

public enum BundleReaderError: Error, Sendable {
    case fileNotFound(String)
}

public enum BundleReader {
    // MARK: - URL resolution (flat bundle layout)

    /// Looks up a file in the bundle by **file name only** (e.g. `icon_categories_header.json`, `read-it-later.html`).
    public static func urlForBundledFileName(_ fileName: String, in bundle: Bundle = .main) -> URL? {
        let trimmed = fileName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        let base = (trimmed as NSString).deletingPathExtension
        let ext = (trimmed as NSString).pathExtension
        return bundle.url(
            forResource: base,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: nil
        )
    }

    /// Backward-compatible: accepts a path string but resolves using **only the last path component** (the file name).
    public static func url(forAssetPath assetPath: String, in bundle: Bundle = .main) -> URL? {
        let trimmed = assetPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        return urlForBundledFileName((trimmed as NSString).lastPathComponent, in: bundle)
    }

    /// Reads UTF-8 text from a bundled file (by path or file name; lookup uses the file name only).
    public static func readAssetText(_ assetPath: String, in bundle: Bundle = .main) throws -> String {
        guard let url = url(forAssetPath: assetPath, in: bundle) else {
            throw BundleReaderError.fileNotFound(assetPath)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Web components (HTML shells + `chunks/` + `assets/` under `WebComponents/`)

    /// Folder under the bundle root (`bundle.bundleURL`) containing Vite output.
    private static let webComponentsSubdirectory = "WebComponents"

    private static func webComponentsDirectoryURL(in bundle: Bundle) -> URL? {
        let root = bundle.bundleURL.standardizedFileURL
        let dir = root.appendingPathComponent(webComponentsSubdirectory, isDirectory: true)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        return dir.standardizedFileURL
    }

    /// Directory URL for `WKWebView.loadFileURL(_:allowingReadAccessTo:)`.
    ///
    /// Uses the `WebComponents` folder directly to match:
    /// `folderURL = Bundle.main.bundleURL.appendingPathComponent("WebComponents")`
    /// `webView.loadFileURL(fileURL, allowingReadAccessTo: folderURL)`
    public static func webComponentsBaseURL(in bundle: Bundle = .main) -> URL? {
        if let dir = webComponentsDirectoryURL(in: bundle) {
            return dir
        }
        // Fallback discovery order when `WebComponents/` is missing as a directory URL but files exist
        // (matches `vite.config.ts` `build.rollupOptions.input` in yaba-web-components).
        let entryNames = [
            "read-it-later.html",
            "preview.html",
            "editor.html",
            "canvas.html",
            "epub-viewer.html",
        ]
        for name in entryNames {
            if let url = webComponentURL(named: name, in: bundle) {
                return url.deletingLastPathComponent().standardizedFileURL
            }
        }
        return nil
    }

    /// Resolves a file under `WebComponents/` using the same path layout as on disk (`bundleURL/WebComponents/...`).
    /// Falls back to `Bundle.url(forResource:…)` then flat bundle root for older layouts.
    public static func webComponentURL(named fileName: String, in bundle: Bundle = .main) -> URL? {
        let trimmed = fileName.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }

        if let dir = webComponentsDirectoryURL(in: bundle) {
            let url = dir.appendingPathComponent(trimmed)
            if FileManager.default.fileExists(atPath: url.path) {
                return url.standardizedFileURL
            }
        }

        let base = (trimmed as NSString).deletingPathExtension
        let ext = (trimmed as NSString).pathExtension
        if let url = bundle.url(
            forResource: base,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: webComponentsSubdirectory
        ) {
            return url.standardizedFileURL
        }
        if let url = bundle.url(
            forResource: base,
            withExtension: ext.isEmpty ? nil : ext,
            subdirectory: nil
        ) {
            return url.standardizedFileURL
        }
        return nil
    }
    
    /// Minified linkedom + Readability + unified/rehype/remark for [HTMLToMarkdownProcessor] (`html-to-markdown.bundle.min.js`). JS returns `{ markdown }` only; inline image rewriting to `yaba-asset://` is done in Swift.
    public static func htmlToMarkdownBundleURL(in bundle: Bundle = .main) -> URL? {
        webComponentURL(named: "html-to-markdown.bundle.min.js", in: bundle)
    }

    // MARK: - WKWebView shells (editor + canvas)

    public static func getEditorURL(in bundle: Bundle = .main) -> URL? {
        webComponentURL(named: "editor.html", in: bundle)
    }

    public static func getCanvasURL(in bundle: Bundle = .main) -> URL? {
        webComponentURL(named: "canvas.html", in: bundle)
    }

    /// File URL with `platform`, `appearance`, and optional `cursor` query for theme bootstrap in the web bundle.
    public static func webShellURLWithQuery(
        named fileName: String,
        platform: WebPlatform,
        appearance: WebAppearance,
        cursor: String? = nil,
        bundle: Bundle = .main
    ) -> URL? {
        guard let base = webComponentURL(named: fileName, in: bundle) else { return nil }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "platform", value: platform.rawValue),
            URLQueryItem(name: "appearance", value: appearance.rawValue),
        ]
        let trimmedCursor = cursor?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedCursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: trimmedCursor))
        }
        components?.queryItems = items
        return components?.url
    }
}
