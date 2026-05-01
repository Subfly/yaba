//
//  Unfurler.swift
//  YABACore
//
//  Fetches remote HTML for linkmarks; strips scripts, then Readability + rehype/remark in JSC for readable markdown + inline images.
//

import Foundation

/// Native link unfurl: HTML → script strip → Readability + Markdown (unified/rehype/remark via JSC) + inline image assets + metadata + preview bytes.
public struct LinkUnfurlResult: Sendable {
    public var metadata: LinkMetadataResult
    public var readable: ReadableUnfurl
    public var previewImageData: Data?
    public var previewIconData: Data?

    public init(
        metadata: LinkMetadataResult,
        readable: ReadableUnfurl,
        previewImageData: Data?,
        previewIconData: Data?
    ) {
        self.metadata = metadata
        self.readable = readable
        self.previewImageData = previewImageData
        self.previewIconData = previewIconData
    }
}

/// Metadata + preview assets only (no readable body processing).
public struct LinkMetadataRefresh: Sendable {
    public var metadata: LinkMetadataResult
    public var previewImageData: Data?
    public var previewIconData: Data?

    public init(metadata: LinkMetadataResult, previewImageData: Data?, previewIconData: Data?) {
        self.metadata = metadata
        self.previewImageData = previewImageData
        self.previewIconData = previewIconData
    }
}

/// Raw HTML fetch result for the converter pipeline.
public struct RawHtmlFetch: Sendable {
    public var normalizedUrl: String
    public var html: String

    public init(normalizedUrl: String, html: String) {
        self.normalizedUrl = normalizedUrl
        self.html = html
    }
}

public enum Unfurler {
    /// Fetch → metadata (raw HTML) → HTML→Markdown → download inline images → preview image/icon bytes.
    public static func unfurl(_ urlString: String) async throws -> LinkUnfurlResult {
        let fetch = try await fetchRawHtml(urlString)
        let meta = try LinkMetadataExtractor.extract(html: fetch.html, pageUrl: fetch.normalizedUrl)
        let baseForAssets = meta.cleanedUrl.nilIfEmpty ?? fetch.normalizedUrl

        let htmlForMarkdown: String
        do {
            htmlForMarkdown = try HTMLPurifier.purify(fetch.html, baseUri: fetch.normalizedUrl)
        } catch {
            throw UnfurlError.htmlSanitizationFailed(String(describing: error))
        }

        let conversion: HTMLToMarkdownConversionResult
        do {
            conversion = try HTMLToMarkdownProcessor.convert(html: htmlForMarkdown, baseURL: baseForAssets)
        } catch {
            throw UnfurlError.htmlToMarkdownFailed(String(describing: error))
        }

        let readable = await downloadReadableInlineAssets(conversion: conversion)
        let previewImageData = await downloadPreviewImageBytes(urlString: meta.image)
        let previewIconData = await downloadPreviewImageBytes(urlString: meta.logo)

        return LinkUnfurlResult(
            metadata: meta,
            readable: readable,
            previewImageData: previewImageData,
            previewIconData: previewIconData
        )
    }

    /// Open Graph / link metadata + preview downloads only (no new readable version).
    public static func fetchMetadataAndPreviews(_ urlString: String) async throws -> LinkMetadataRefresh {
        let fetch = try await fetchRawHtml(urlString)
        let meta = try LinkMetadataExtractor.extract(html: fetch.html, pageUrl: fetch.normalizedUrl)
        let previewImageData = await downloadPreviewImageBytes(urlString: meta.image)
        let previewIconData = await downloadPreviewImageBytes(urlString: meta.logo)
        return LinkMetadataRefresh(
            metadata: meta,
            previewImageData: previewImageData,
            previewIconData: previewIconData
        )
    }

    /// Normalizes the URL string and downloads raw HTML (Compose `Unfurler.unfurl` HTTP portion).
    public static func fetchRawHtml(_ urlString: String) async throws -> RawHtmlFetch {
        let normalized = normalizeURL(urlString)
        guard let url = URL(string: normalized) else {
            throw UnfurlError.cannotCreateURL(normalized)
        }
        let html = try await UnfurlHttpClient.getHtmlString(url: url)
        guard !html.isEmpty else {
            throw UnfurlError.unableToFetchHtml
        }
        return RawHtmlFetch(normalizedUrl: normalized, html: html)
    }

    /// Downloads image bytes for bookmark preview (card image / logo) from metadata URLs.
    public static func downloadPreviewImageBytes(urlString: String?) async -> Data? {
        guard let urlString = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !urlString.isEmpty,
              let url = URL(string: urlString)
        else { return nil }
        return try? await UnfurlHttpClient.getBytes(url: url)
    }

    private static func normalizeURL(_ urlString: String) -> String {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if (normalized.hasPrefix("\"") && normalized.hasSuffix("\"")) ||
            (normalized.hasPrefix("'") && normalized.hasSuffix("'")) {
            normalized = String(normalized.dropFirst().dropLast())
        }
        let lower = normalized.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            // keep
        } else if lower.hasPrefix("www.") {
            normalized = "https://\(normalized)"
        } else if lower.hasPrefix("//") {
            normalized = "https:\(normalized)"
        } else if lower.hasPrefix("ftp://") || lower.hasPrefix("file://") || lower.hasPrefix("mailto:") {
            // keep
        } else if normalized.contains("."), !normalized.contains(" ") {
            normalized = "https://\(normalized)"
        }
        if let protocolRange = normalized.range(of: "://") {
            let protocolPart = String(normalized[..<protocolRange.upperBound])
            let pathPart = String(normalized[protocolRange.upperBound...])
            let cleanedPath = pathPart.replacingOccurrences(of: "//+", with: "/", options: .regularExpression)
            normalized = protocolPart + cleanedPath
        }
        return normalized
    }

    // MARK: - Readable inline images

    private static func downloadReadableInlineAssets(conversion: HTMLToMarkdownConversionResult) async -> ReadableUnfurl {
        var payloads: [ReadableAssetPayload] = []
        payloads.reserveCapacity(conversion.assets.count)

        for asset in conversion.assets {
            let trimmedUrl = asset.url.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmedUrl),
                  url.scheme == "http" || url.scheme == "https"
            else { continue }

            guard let rawBytes = try? await UnfurlHttpClient.getBytes(url: url), !rawBytes.isEmpty else { continue }

            let compressed = YabaImageCompression.compressDataPreservingFormat(rawBytes)
            let ext = mapStoredImageExtension(inferReadableImageExtension(bytes: compressed, urlString: trimmedUrl))
            payloads.append(
                ReadableAssetPayload(assetId: asset.assetId, pathExtension: ext, bytes: compressed)
            )
        }

        return ReadableUnfurl(markdown: conversion.markdown, assets: payloads)
    }

    /// Parity with Compose `mapAssetExtensionForPath`.
    private static func mapStoredImageExtension(_ ext: String) -> String {
        let e = ext.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ".", with: "")
        if e == "jpg" { return "jpeg" }
        return e.isEmpty ? "jpeg" : e
    }

    /// Parity with Compose `inferImageExtension`.
    private static func inferReadableImageExtension(bytes: Data, urlString: String) -> String {
        guard bytes.count >= 3 else { return inferReadableImageExtensionFromURL(urlString) }
        let b = [UInt8](bytes.prefix(12))
        if b.count >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF {
            return "jpg"
        }
        if b.count >= 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 {
            return "png"
        }
        if b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 {
            return "gif"
        }
        if b.count >= 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46
            && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50
        {
            return "webp"
        }
        return inferReadableImageExtensionFromURL(urlString)
    }

    private static func inferReadableImageExtensionFromURL(_ urlString: String) -> String {
        let urlLower = urlString.lowercased()
        if urlLower.contains(".png") { return "png" }
        if urlLower.contains(".gif") { return "gif" }
        if urlLower.contains(".webp") { return "webp" }
        if urlLower.contains(".jpeg") || urlLower.contains(".jpg") { return "jpg" }
        return "jpg"
    }
}
