//
//  HTMLToMarkdownProcessor.swift
//  YABACore
//
//  Loads the minified bundle (linkedom + Mozilla Readability, then unified + rehype + remark) and converts HTML to Markdown on JavaScriptCore
//  (no WKWebView). The bundle is produced by `Extensions/yaba-web-components` (see
//  `html-to-markdown.bundle.min.js`).
//

import Foundation
import JavaScriptCore

/// Remote image referenced from markdown before download; identifiers match `yaba-asset://` in the markdown body.
public struct HTMLToMarkdownRemoteAsset: Sendable, Codable, Equatable {
    public var assetId: String
    public var url: String

    public init(assetId: String, url: String) {
        self.assetId = assetId
        self.url = url
    }
}

/// Output of `globalThis.HTMLToMarkdown(html, baseURL)` — JSON `{ markdown, assets }`.
public struct HTMLToMarkdownConversionResult: Sendable, Codable, Equatable {
    public var markdown: String
    public var assets: [HTMLToMarkdownRemoteAsset]

    public init(markdown: String, assets: [HTMLToMarkdownRemoteAsset]) {
        self.markdown = markdown
        self.assets = assets
    }
}

public enum HTMLToMarkdownError: Error, Sendable {
    case bundleNotFound
    case bundleReadFailed(String)
    case javaScriptContextInitFailed
    case functionMissing
    case javaScriptException(String)
    case conversionPayloadInvalid(String)
}

public enum HTMLToMarkdownProcessor: Sendable {
    private static let lock: NSLock = {
        let l = NSLock()
        l.name = "YABA.HTMLToMarkdown"
        return l
    }()

    /// Serializes access with `lock`; do not use off-main without keeping the same isolation as `convert`.
    private static var cachedContext: JSContext?

    /// Converts `html` to CommonMark + GFM markdown using `globalThis.HTMLToMarkdown` from the bundled script (Readability article HTML, then rehype → remark).
    /// Inline HTTP(S) images are rewritten to `yaba-asset://<UUID>` in markdown; `assets` lists absolute download URLs keyed by those ids.
    /// - Parameters:
    ///   - html: Full HTML (or a fragment) as fetched from the page.
    ///   - baseURL: Page URL used to resolve relative image paths in the resulting markdown (e.g. `/pic.png` → absolute URL).
    public static func convert(html: String, baseURL: String) throws -> HTMLToMarkdownConversionResult {
        lock.lock()
        defer { lock.unlock() }

        let context: JSContext
        if let cached = Self.cachedContext {
            context = cached
        } else {
            let newContext = try loadAndEvaluateBundle()
            Self.cachedContext = newContext
            context = newContext
        }
        return try callHTMLToMarkdown(context: context, html: html, baseURL: baseURL)
    }

    private static func loadAndEvaluateBundle() throws -> JSContext {
        let ctx = JSContext()!
        // Do not `assertionFailure` here: it crashes the app in DEBUG on normal JS throws (e.g. bad HTML).
        // Errors are returned via `context.exception` after `callHTMLToMarkdown`.
        guard let url = BundleReader.htmlToMarkdownBundleURL() else {
            throw HTMLToMarkdownError.bundleNotFound
        }
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw HTMLToMarkdownError.bundleReadFailed(String(describing: error))
        }
        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw HTMLToMarkdownError.bundleReadFailed("empty bundle")
        }
        _ = ctx.evaluateScript(source, withSourceURL: url)
        if let exc = ctx.exception, !exc.isUndefined {
            throw HTMLToMarkdownError.javaScriptException(exc.toString() ?? "unknown")
        }
        guard
            let fn = ctx.globalObject?.objectForKeyedSubscript("HTMLToMarkdown"), !fn.isUndefined
        else {
            throw HTMLToMarkdownError.functionMissing
        }
        return ctx
    }

    private static func callHTMLToMarkdown(context: JSContext, html: String, baseURL: String) throws -> HTMLToMarkdownConversionResult {
        guard
            let fn = context.globalObject?.objectForKeyedSubscript("HTMLToMarkdown"), !fn.isUndefined
        else {
            throw HTMLToMarkdownError.functionMissing
        }
        let htmlValue = JSValue(object: html, in: context) ?? JSValue(nullIn: context)
        let baseValue = JSValue(object: baseURL, in: context) ?? JSValue(nullIn: context)
        context.exception = nil
        let result = fn.call(withArguments: [htmlValue, baseValue])
        if let exc = context.exception, !exc.isUndefined {
            let text = exc.isString ? (exc.toString() ?? "unknown") : (exc.toString() ?? "unknown")
            throw HTMLToMarkdownError.javaScriptException(text)
        }
        guard let result, !result.isUndefined, !result.isNull else {
            throw HTMLToMarkdownError.conversionPayloadInvalid("null result")
        }
        guard let jsonString = result.toString(), !jsonString.isEmpty else {
            throw HTMLToMarkdownError.conversionPayloadInvalid("non-string result")
        }
        guard let data = jsonString.data(using: .utf8) else {
            throw HTMLToMarkdownError.conversionPayloadInvalid("utf8 encode failed")
        }
        do {
            return try JSONDecoder().decode(HTMLToMarkdownConversionResult.self, from: data)
        } catch {
            throw HTMLToMarkdownError.conversionPayloadInvalid(String(describing: error))
        }
    }
}
