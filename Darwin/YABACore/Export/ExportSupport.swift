//
//  ExportSupport.swift
//  YABACore
//
//  Saving exports to user-picked locations: Markdown bundles (`note.md` + `assets/`) and single documents (PDF, CSV, …).
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
#endif

// MARK: - Models

public struct MarkdownExportAsset: Sendable, Equatable {
    public let fileName: String
    public let bytes: Data

    public init(fileName: String, bytes: Data) {
        self.fileName = fileName
        self.bytes = bytes
    }
}

public struct MarkdownExportRequest: Sendable, Equatable {
    public let markdown: String
    public let baseFolderName: String
    public let assets: [MarkdownExportAsset]

    public init(markdown: String, baseFolderName: String, assets: [MarkdownExportAsset]) {
        self.markdown = markdown
        self.baseFolderName = baseFolderName
        self.assets = assets
    }
}

/// App-agnostic inline image payload for building export filenames (`<id>.<ext>`).
public struct MarkdownExportInlineSource: Sendable, Equatable {
    public var assetId: String
    public var pathExtension: String
    public var bytes: Data

    public init(assetId: String, pathExtension: String, bytes: Data) {
        self.assetId = assetId
        self.pathExtension = pathExtension
        self.bytes = bytes
    }
}

// MARK: - Writing + helpers

public enum ExportSupport {
    /// Writes `<parent>/<baseFolderName>/note.md` and `<parent>/<baseFolderName>/assets/*`.
    public static func writeBundle(_ request: MarkdownExportRequest, into selectedDirectory: URL) -> Bool {
        let scoped = selectedDirectory.startAccessingSecurityScopedResource()
        defer {
            if scoped { selectedDirectory.stopAccessingSecurityScopedResource() }
        }
        let fileManager = FileManager.default
        do {
            let exportRoot = selectedDirectory
                .appendingPathComponent(request.baseFolderName, isDirectory: true)
            let assetsDir = exportRoot.appendingPathComponent("assets", isDirectory: true)
            try fileManager.createDirectory(at: exportRoot, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)
            let markdownFile = exportRoot.appendingPathComponent("note.md", isDirectory: false)
            let markdownForDisk = Self.sanitizeYabaAssetURLsInMarkdownForExport(request.markdown, assets: request.assets)
            guard let markdownData = markdownForDisk.data(using: .utf8) else { return false }
            try markdownData.write(to: markdownFile, options: .atomic)
            for asset in request.assets {
                let file = assetsDir.appendingPathComponent(asset.fileName, isDirectory: false)
                try asset.bytes.write(to: file, options: .atomic)
            }
            return true
        } catch {
            return false
        }
    }

    /// Writes `<parent>/<safeBaseName>.<pathExtension>` (e.g. `pdf`, `csv`) using security-scoped access.
    public static func writeExportedDocument(
        data: Data,
        into parentDirectory: URL,
        fileBaseName: String,
        pathExtension ext: String
    ) -> Bool {
        let scoped = parentDirectory.startAccessingSecurityScopedResource()
        defer {
            if scoped { parentDirectory.stopAccessingSecurityScopedResource() }
        }
        let safeName = sanitizeBaseFolderName(fileBaseName, emptyFallback: "reader")
        let sanitizedExt = ext.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        let normalizedExt = sanitizedExt.hasPrefix(".")
            ? String(sanitizedExt.dropFirst())
            : sanitizedExt
        let finalExt = normalizedExt.isEmpty ? "pdf" : normalizedExt
        let fileURL = parentDirectory.appendingPathComponent("\(safeName).\(finalExt)", isDirectory: false)
        do {
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    public static func sanitizeBaseFolderName(_ label: String, emptyFallback: String = "note") -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return emptyFallback }
        let sanitized = String(trimmed.map { char in
            if char.isLetter || char.isNumber || char == "_" || char == "-" {
                return char
            }
            return "_"
        })
        return sanitized.isEmpty ? emptyFallback : sanitized
    }

    /// Maps inline sources to on-disk `assets/` filenames (`<assetId>.<ext>`).
    public static func exportAssets(from sources: [MarkdownExportInlineSource]) -> [MarkdownExportAsset] {
        sources.map { item in
            let ext = item.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedExt = ext.isEmpty ? "bin" : ext
            return MarkdownExportAsset(fileName: "\(item.assetId).\(cleanedExt)", bytes: item.bytes)
        }
    }

    /// Rewrites `yaba-asset://…` placeholders to `./assets/<fileName>` (matching files written under `assets/`).
    /// Used only for on-disk export; the stored markdown body is unchanged.
    private static func sanitizeYabaAssetURLsInMarkdownForExport(_ markdown: String, assets: [MarkdownExportAsset]) -> String {
        guard !markdown.isEmpty else { return markdown }
        var idToRelative: [String: String] = [:]
        idToRelative.reserveCapacity(assets.count)
        for asset in assets {
            let base = (asset.fileName as NSString).deletingPathExtension
            guard !base.isEmpty else { continue }
            idToRelative[base.lowercased()] = "./assets/\(asset.fileName)"
        }
        guard let regex = try? NSRegularExpression(
            pattern: #"yaba-asset://[^\s<>\]\)"']+"#,
            options: .caseInsensitive
        ) else {
            return markdown
        }
        let ns = markdown as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: markdown, options: [], range: fullRange)
        guard !matches.isEmpty else { return markdown }
        let result = NSMutableString(string: markdown)
        for match in matches.reversed() {
            let raw = ns.substring(with: match.range(at: 0))
            guard let id = assetIdToken(fromYabaAssetURLString: raw) else { continue }
            let replacement = idToRelative[id.lowercased()] ?? "./assets/\(id)"
            result.replaceCharacters(in: match.range(at: 0), with: replacement)
        }
        return result as String
    }

    /// Aligns with ``YabaInlineAssetSchemeHandler`` / stored inline asset URL shapes (`yaba-asset://<id>`, `…/assets/<id>.<ext>`, …).
    private static func assetIdToken(fromYabaAssetURLString raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let noQuery = trimmed.split(separator: "?", maxSplits: 1).first.map(String.init) ?? trimmed
        let noHash = noQuery.split(separator: "#", maxSplits: 1).first.map(String.init) ?? noQuery

        let pathPart: String
        if let range = noHash.range(of: "/assets/", options: .backwards) {
            pathPart = String(noHash[range.upperBound...])
        } else if let range = noHash.range(of: "://") {
            pathPart = String(noHash[range.upperBound...])
        } else if let range = noHash.range(of: ":", options: .backwards) {
            pathPart = String(noHash[noHash.index(after: range.lowerBound)...])
        } else {
            return nil
        }
        return normalizedInlineAssetIdToken(pathPart)
    }

    private static func normalizedInlineAssetIdToken(_ raw: String) -> String? {
        var token = (raw.removingPercentEncoding ?? raw).trimmingCharacters(in: .whitespacesAndNewlines)
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
}

// MARK: - Directory picker (export destination)

public struct ExportDirectoryPicker: UIViewControllerRepresentable {
    public let onPicked: (URL?) -> Void

    public init(onPicked: @escaping (URL?) -> Void) {
        self.onPicked = onPicked
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.folder],
            asCopy: false
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.modalPresentationStyle = .formSheet
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPicked: (URL?) -> Void
        private var didFinish = false

        public init(onPicked: @escaping (URL?) -> Void) {
            self.onPicked = onPicked
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard !didFinish else { return }
            didFinish = true
            onPicked(urls.first)
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            guard !didFinish else { return }
            didFinish = true
            onPicked(nil)
        }
    }
}
