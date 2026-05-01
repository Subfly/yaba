//
//  HTMLToMarkdownProcessor.swift
//  YABACore
//
//  Loads the minified bundle (linkedom + Mozilla Readability, then unified + rehype + remark) and converts HTML to Markdown on JavaScriptCore
//  (no WKWebView). The bundle is produced by `Extensions/yaba-web-components` (see
//  `html-to-markdown.bundle.min.js`).
//  Remote image URLs in markdown are rewritten to `yaba-asset://<uuid>` and listed in `assets` on the Swift side so behavior matches across engines.
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

/// Result of `convert`: markdown with `yaba-asset://` placeholders and downloadable source URLs.
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

/// JSON `{ markdown }` returned from `globalThis.HTMLToMarkdown` (no `assets` in JS).
private struct HTMLToMarkdownJSResponse: Decodable {
    var markdown: String
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
        let rawMarkdown = try callHTMLToMarkdownRaw(context: context, html: html, baseURL: baseURL)
        return rewriteMarkdownRemoteAssets(markdown: rawMarkdown, baseURL: baseURL)
    }

    private static func loadAndEvaluateBundle() throws -> JSContext {
        let ctx = JSContext()!
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

    private static func callHTMLToMarkdownRaw(context: JSContext, html: String, baseURL: String) throws -> String {
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
            return try JSONDecoder().decode(HTMLToMarkdownJSResponse.self, from: data).markdown
        } catch {
            throw HTMLToMarkdownError.conversionPayloadInvalid(String(describing: error))
        }
    }

    // MARK: - Remote asset rewrite (Swift; was JavaScript)

    private static func rewriteMarkdownRemoteAssets(markdown: String, baseURL: String) -> HTMLToMarkdownConversionResult {
        var assets: [HTMLToMarkdownRemoteAsset] = []
        var out = rewriteInlineMarkdownImages(markdown: markdown, baseURL: baseURL, assets: &assets)
        out = rewriteReferenceMarkdownImages(markdown: out, baseURL: baseURL, assets: &assets)
        out = rewriteHtmlImgTags(markdown: out, baseURL: baseURL, assets: &assets)
        return HTMLToMarkdownConversionResult(markdown: out, assets: assets)
    }

    /// First whitespace-delimited segment; strips optional `<` / `>` wrappers (CommonMark autolinks / destinations).
    private static func extractImageDestination(_ raw: String) -> String {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("<") { trimmed.removeFirst() }
        if trimmed.hasSuffix(">") { trimmed.removeLast() }
        trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.split { $0.isWhitespace }.first.map(String.init) ?? ""
    }

    private static func resolveImageUrl(_ raw: String, baseURL: String) -> String? {
        let trimmed = extractImageDestination(raw)
        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.lowercased().hasPrefix("data:") else { return nil }

        let href: String
        if trimmed.range(of: #"^https?://"#, options: [.regularExpression, .caseInsensitive]) != nil {
            href = trimmed
        } else if trimmed.hasPrefix("//") {
            guard let u = URL(string: "https:\(trimmed)") else { return nil }
            href = u.absoluteString
        } else {
            let base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !base.isEmpty, let baseParsed = URL(string: base) else { return nil }
            guard let resolved = URL(string: trimmed, relativeTo: baseParsed) else { return nil }
            href = resolved.absoluteString
        }
        guard let parsed = URL(string: href),
              let scheme = parsed.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return href
    }

    /// Closing `)` for `(...)`, honoring double-quoted segments (remark titles with `)` inside quotes).
    private static func scanClosingParenForMarkdownImage(_ string: String, openParen: String.Index) -> String.Index? {
        guard openParen < string.endIndex, string[openParen] == "(" else { return nil }
        var index = string.index(after: openParen)
        var depth = 1
        var inDoubleQuote = false
        while index < string.endIndex {
            let c = string[index]
            if c == "\\" {
                index = string.index(after: index)
                if index < string.endIndex { index = string.index(after: index) }
                continue
            }
            if c == "\"" {
                inDoubleQuote.toggle()
                index = string.index(after: index)
                continue
            }
            if inDoubleQuote {
                index = string.index(after: index)
                continue
            }
            if c == "(" {
                depth += 1
                index = string.index(after: index)
                continue
            }
            if c == ")" {
                depth -= 1
                if depth == 0 { return index }
                index = string.index(after: index)
                continue
            }
            index = string.index(after: index)
        }
        return nil
    }

    private static func rewriteInlineMarkdownImages(
        markdown: String,
        baseURL: String,
        assets: inout [HTMLToMarkdownRemoteAsset]
    ) -> String {
        var out = ""
        var current = markdown.startIndex
        while current < markdown.endIndex {
            guard let bangRange = markdown.range(of: "![", range: current ..< markdown.endIndex) else {
                out.append(String(markdown[current...]))
                break
            }
            let start = bangRange.lowerBound
            out.append(String(markdown[current..<start]))
            let innerStart = markdown.index(start, offsetBy: 2)
            guard innerStart < markdown.endIndex,
                  let closeChunk = markdown[innerStart..<markdown.endIndex].range(of: "](")
            else {
                out.append(String(markdown[start..<innerStart]))
                current = innerStart
                continue
            }
            let bracket = closeChunk.lowerBound
            let alt = String(markdown[innerStart..<bracket])
            let openParen = markdown.index(bracket, offsetBy: 1)
            guard openParen < markdown.endIndex, markdown[openParen] == "(" else {
                out.append(String(markdown[start...bracket]))
                current = markdown.index(after: bracket)
                continue
            }
            let destStart = markdown.index(after: openParen)
            guard let closingParen = scanClosingParenForMarkdownImage(markdown, openParen: openParen) else {
                out.append(String(markdown[start..<markdown.index(after: openParen)]))
                current = markdown.index(after: openParen)
                continue
            }
            let rawDest = String(markdown[destStart..<closingParen])
            let fullEnd = markdown.index(after: closingParen)
            if let resolved = resolveImageUrl(rawDest, baseURL: baseURL) {
                let id = UUID().uuidString
                assets.append(HTMLToMarkdownRemoteAsset(assetId: id, url: resolved))
                out.append("![\(alt)](yaba-asset://\(id))")
            } else {
                out.append(String(markdown[start..<fullEnd]))
            }
            current = fullEnd
        }
        return out
    }

    private static func rewriteReferenceMarkdownImages(
        markdown: String,
        baseURL: String,
        assets: inout [HTMLToMarkdownRemoteAsset]
    ) -> String {
        guard let usageRegex = try? NSRegularExpression(
            pattern: "!\\[[^\\]]*\\]\\[([^\\]]*)\\]",
            options: []
        ) else { return markdown }
        let nsOrig = markdown as NSString
        let len = nsOrig.length
        var refIds = Set<String>()
        usageRegex.enumerateMatches(in: markdown, options: [], range: NSRange(location: 0, length: len)) { result, _, _ in
            guard let m = result, m.numberOfRanges >= 2 else { return }
            let id = (nsOrig.substring(with: m.range(at: 1)) as String)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if !id.isEmpty { refIds.insert(id) }
        }
        guard !refIds.isEmpty else { return markdown }
        guard let defRegex = try? NSRegularExpression(
            pattern: "^\\[([^\\]]+)\\]:\\s*(\\S.*)$",
            options: [.anchorsMatchLines]
        ) else { return markdown }
        let matches = defRegex.matches(in: markdown, range: NSRange(location: 0, length: len))
            .sorted { $0.range.location > $1.range.location }
        let result = NSMutableString(string: markdown)
        for m in matches {
            guard m.numberOfRanges >= 3 else { continue }
            let rawId = nsOrig.substring(with: m.range(at: 1))
            let id = rawId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard refIds.contains(id) else { continue }
            let rawDest = nsOrig.substring(with: m.range(at: 2))
            guard let resolved = resolveImageUrl(rawDest, baseURL: baseURL) else { continue }
            let assetId = UUID().uuidString
            assets.append(HTMLToMarkdownRemoteAsset(assetId: assetId, url: resolved))
            let replacement = "[\(rawId)]: yaba-asset://\(assetId)"
            result.replaceCharacters(in: m.range(at: 0), with: replacement)
        }
        return result as String
    }

    private static func rewriteHtmlImgTags(
        markdown: String,
        baseURL: String,
        assets: inout [HTMLToMarkdownRemoteAsset]
    ) -> String {
        let pattern = "(<img\\b[^>]*\\bsrc\\s*=\\s*)([\"'])([^\"']+)\\2"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return markdown }
        let nsOrig = markdown as NSString
        let len = nsOrig.length
        let all = regex.matches(in: markdown, range: NSRange(location: 0, length: len))
            .sorted { $0.range.location > $1.range.location }
        let result = NSMutableString(string: markdown)
        for m in all {
            guard m.numberOfRanges >= 4 else { continue }
            let prefix = nsOrig.substring(with: m.range(at: 1))
            let quote = nsOrig.substring(with: m.range(at: 2))
            let src = nsOrig.substring(with: m.range(at: 3))
            guard let resolved = resolveImageUrl(src, baseURL: baseURL) else { continue }
            let assetId = UUID().uuidString
            assets.append(HTMLToMarkdownRemoteAsset(assetId: assetId, url: resolved))
            let replacement = "\(prefix)\(quote)yaba-asset://\(assetId)\(quote)"
            result.replaceCharacters(in: m.range(at: 0), with: replacement)
        }
        return result as String
    }
}
