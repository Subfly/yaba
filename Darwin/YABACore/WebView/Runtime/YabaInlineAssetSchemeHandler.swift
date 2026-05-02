//
//  YabaInlineAssetSchemeHandler.swift
//  YABACore
//
//  Serves `yaba-asset://` subresources in Markdown preview (link + notemark readers).
//

import Foundation
import WebKit

public struct YabaInlineAssetPayload: Sendable {
    public let assetId: String
    public let pathExtension: String
    public let bytes: Data

    public init(assetId: String, pathExtension: String, bytes: Data) {
        self.assetId = assetId
        self.pathExtension = pathExtension
        self.bytes = bytes
    }

    init?(inlineAsset item: InlineAssetModel) {
        guard let bytes = item.bytes, !bytes.isEmpty else { return nil }
        self.init(
            assetId: item.assetId,
            pathExtension: Self.normalizedPathExtension(item.pathExtension),
            bytes: bytes
        )
    }

    private static func normalizedPathExtension(_ raw: String) -> String {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        if normalized == "jpg" { return "jpeg" }
        return normalized.isEmpty ? "jpeg" : normalized
    }
}

/// Resolves `yaba-asset://<id>` (and path variants) using an in-memory map updated from SwiftData.
public final class YabaInlineAssetSchemeHandler: NSObject, WKURLSchemeHandler {
    private let lock = NSLock()
    private var assetsById: [String: YabaInlineAssetPayload] = [:]

    public func updateAssets(_ assets: [YabaInlineAssetPayload]) {
        var map: [String: YabaInlineAssetPayload] = [:]
        map.reserveCapacity(assets.count)
        for item in assets {
            map[item.assetId] = item
        }
        lock.lock()
        assetsById = map
        lock.unlock()
    }

    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let requestURL = urlSchemeTask.request.url,
              let payload = resolveAsset(for: requestURL)
        else {
            let error = NSError(domain: "YABA.YabaInlineAssetScheme", code: 404)
            urlSchemeTask.didFailWithError(error)
            return
        }

        let response = URLResponse(
            url: requestURL,
            mimeType: mimeType(forPathExtension: payload.pathExtension),
            expectedContentLength: payload.bytes.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(payload.bytes)
        urlSchemeTask.didFinish()
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func resolveAsset(for url: URL) -> YabaInlineAssetPayload? {
        let candidateId = assetIdCandidate(for: url)
        guard let candidateId else { return nil }

        lock.lock()
        let payload = assetsById[candidateId]
        lock.unlock()
        return payload
    }

    private func assetIdCandidate(for url: URL) -> String? {
        // Prefer parsing the raw URL string so we can support both host-based
        // (`yaba-asset://<id>`) and path-based (`yaba-asset:///assets/<id>.ext`) forms.
        if let fromAbsoluteString = assetIdFromAbsoluteString(url.absoluteString) {
            return fromAbsoluteString
        }

        let pathSegments = url.pathComponents.filter { $0 != "/" }
        if let last = pathSegments.last, !last.isEmpty {
            if last == "assets", let host = url.host, !host.isEmpty {
                return normalizedAssetIdToken(host)
            }
            if let normalized = normalizedAssetIdToken(last) {
                return normalized
            }
        }
        if let host = url.host, !host.isEmpty {
            return normalizedAssetIdToken(host)
        }
        return nil
    }

    private func assetIdFromAbsoluteString(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let noQuery = trimmed.split(separator: "?", maxSplits: 1).first.map(String.init) ?? trimmed
        let noHash = noQuery.split(separator: "#", maxSplits: 1).first.map(String.init) ?? noQuery

        if let range = noHash.range(of: "/assets/", options: .backwards) {
            let tail = String(noHash[range.upperBound...])
            return normalizedAssetIdToken(tail)
        }

        if let range = noHash.range(of: "://") {
            let tail = String(noHash[range.upperBound...])
            return normalizedAssetIdToken(tail)
        }
        if let range = noHash.range(of: ":", options: .backwards) {
            let tail = String(noHash[noHash.index(after: range.lowerBound)...])
            return normalizedAssetIdToken(tail)
        }
        return normalizedAssetIdToken(noHash)
    }

    private func normalizedAssetIdToken(_ raw: String) -> String? {
        let decoded = raw.removingPercentEncoding ?? raw
        let trimmed = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var token = trimmed
        token = token.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if token.hasPrefix("assets/") {
            token = String(token.dropFirst("assets/".count))
        }
        if let slash = token.lastIndex(of: "/") {
            token = String(token[token.index(after: slash)...])
        }

        guard !token.isEmpty else { return nil }
        let base = (token as NSString).deletingPathExtension
        return base.isEmpty ? token : base
    }

    private func mimeType(forPathExtension ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "svg": return "image/svg+xml"
        case "bmp": return "image/bmp"
        case "ico": return "image/x-icon"
        default: return "application/octet-stream"
        }
    }
}
