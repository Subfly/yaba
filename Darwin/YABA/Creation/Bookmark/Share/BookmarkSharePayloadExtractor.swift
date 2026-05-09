//
//  BookmarkSharePayloadExtractor.swift
//  YABA
//

import Foundation
import UniformTypeIdentifiers

/// Resolves a single payload from a share extension request.
///
/// If multiple items are shared, the first supported payload wins.
enum BookmarkSharePayloadExtractor {
    static func firstPayload(from extensionItems: [NSExtensionItem]) async -> BookmarkShareIncomingPayload? {
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if let payload = await resolve(provider: provider) {
                    return payload
                }
            }
        }
        return nil
    }

    private static func resolve(provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        if let link = await extractHttpLink(from: provider) { return link }
        if let document = await extractDocument(from: provider) { return document }
        if let image = await extractImage(from: provider) { return image }
        if let audio = await extractAudio(from: provider) { return audio }
        if let video = await extractVideo(from: provider) { return video }
        return await extractPlainNote(from: provider)
    }

    // MARK: Link

    private static func extractHttpLink(from provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        if provider.canLoadObject(ofClass: URL.self),
           let url = await loadURLObject(from: provider),
           let link = asHttpLink(url)
        {
            return .link(link)
        }

        let typeIds = prioritizedTypeIds(["public.url", UTType.url.identifier], provider: provider)
        for typeId in typeIds {
            guard let item = await loadItem(from: provider, typeIdentifier: typeId) else { continue }
            if let url = coerceURL(item), let link = asHttpLink(url) {
                return .link(link)
            }
            if let text = coerceString(item), let link = asHttpLink(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return .link(link)
            }
        }

        guard let text = await loadPlainText(from: provider) else { return nil }
        guard let link = asHttpLink(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return .link(link)
    }

    private static func asHttpLink(_ url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        guard !url.absoluteString.isEmpty else { return nil }
        return url.absoluteString
    }

    private static func asHttpLink(_ raw: String) -> String? {
        guard let url = URL(string: raw) else { return nil }
        return asHttpLink(url)
    }

    // MARK: Document

    private static func extractDocument(from provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        let candidates: [(UTType, DocmarkType)] = [
            (.pdf, .pdf),
            (.epub, .epub),
            (.commaSeparatedText, .csv),
        ]

        for (type, docmarkType) in candidates {
            guard let data = await loadData(from: provider, type: type), !data.isEmpty else { continue }
            let fileName = suggestedDocumentFilename(from: provider.suggestedName, kind: docmarkType)
            return .document(data, fileName: fileName, docmarkType)
        }

        if let fileURL = await loadFileURL(from: provider),
           let kind = docKind(forExtension: fileURL.pathExtension.lowercased()),
           let data = secureRead(fileURL),
           !data.isEmpty
        {
            let fileName = suggestedDocumentFilename(
                from: provider.suggestedName ?? fileURL.lastPathComponent,
                kind: kind
            )
            return .document(data, fileName: fileName, kind)
        }

        if provider.suggestedName?.lowercased().hasSuffix(".csv") == true,
           let plain = await loadPlainText(from: provider),
           let data = plain.data(using: .utf8),
           !data.isEmpty,
           looksCsvLike(data)
        {
            return .document(data, fileName: normalizeCsvFilename(provider.suggestedName), .csv)
        }

        return nil
    }

    private static func suggestedDocumentFilename(from rawName: String?, kind: DocmarkType) -> String {
        let expectedExt: String = switch kind {
        case .pdf: "pdf"
        case .epub: "epub"
        case .csv: "csv"
        }

        guard let rawName = rawName?.trimmingCharacters(in: .whitespacesAndNewlines), !rawName.isEmpty else {
            return "shared.\(expectedExt)"
        }

        let path = URL(fileURLWithPath: rawName)
        let ext = path.pathExtension.lowercased()
        if ext.isEmpty {
            return "\(rawName).\(expectedExt)"
        }
        if ext == expectedExt {
            return rawName
        }

        if kind == .csv {
            return rawName.lowercased().hasSuffix(".csv") ? rawName : "\(rawName).csv"
        }

        return path.deletingPathExtension().lastPathComponent + ".\(expectedExt)"
    }

    private static func docKind(forExtension ext: String) -> DocmarkType? {
        switch ext {
        case "pdf": .pdf
        case "epub": .epub
        case "csv": .csv
        default: nil
        }
    }

    private static func normalizeCsvFilename(_ rawName: String?) -> String {
        guard let rawName, !rawName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "shared.csv" }
        return rawName.lowercased().hasSuffix(".csv") ? rawName : "\(rawName).csv"
    }

    private static func looksCsvLike(_ data: Data) -> Bool {
        guard let sample = String(data: data.prefix(4096), encoding: .utf8) else { return true }
        return sample.contains(where: \.isNewline) && (sample.contains(",") || sample.contains(";") || sample.contains("\t"))
    }

    // MARK: Image

    private static func extractImage(from provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        let imageTypes: [UTType] = [.image, .png, .jpeg, .gif]
        for type in imageTypes {
            guard let data = await loadData(from: provider, type: type), !data.isEmpty else { continue }
            let ext = fileExtension(from: provider.suggestedName) ?? type.preferredFilenameExtension ?? "png"
            return .image(data, fileExtension: ext.lowercased())
        }
        return nil
    }

    // MARK: Audio

    private static func extractAudio(from provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        let audioTypes = ["mp3", "wav", "flac", "m4a", "aac", "caf"]
            .compactMap { UTType(filenameExtension: $0) } + [UTType.audio]

        for type in dedupe(audioTypes) {
            guard let data = await loadData(from: provider, type: type), !data.isEmpty else { continue }
            let ext = normalizedAudioExtension(fileExtension(from: provider.suggestedName) ?? type.preferredFilenameExtension ?? "wav")
            if isVideoExtension(ext) { continue }
            return .audio(data, fileExtension: ext)
        }
        return nil
    }

    private static func normalizedAudioExtension(_ ext: String) -> String {
        let lowered = ext.lowercased()
        return lowered == "caf" ? "m4a" : lowered
    }

    // MARK: Video

    private static func extractVideo(from provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        let videoTypes: [UTType] = [.movie, .mpeg4Movie]
        for type in videoTypes {
            guard let data = await loadData(from: provider, type: type), !data.isEmpty else { continue }
            let ext = fileExtension(from: provider.suggestedName) ?? type.preferredFilenameExtension ?? "mp4"
            if isAudioExtension(ext) { continue }
            let thumb = try? VideoThumbnailGenerator.randomPNGThumbnailData(fromMovieBytes: data, fileExtension: ext)
            return .video(data, thumbnailData: thumb, fileExtension: ext.lowercased())
        }
        return nil
    }

    private static func isVideoExtension(_ ext: String) -> Bool {
        ["mp4", "mov", "m4v", "avi", "mkv", "webm"].contains(ext.lowercased())
    }

    private static func isAudioExtension(_ ext: String) -> Bool {
        ["mp3", "wav", "flac", "m4a", "aac", "caf", "opus"].contains(ext.lowercased())
    }

    // MARK: Note markdown

    private static func extractPlainNote(from provider: NSItemProvider) async -> BookmarkShareIncomingPayload? {
        guard let plain = await loadPlainText(from: provider) else { return nil }
        let trimmed = plain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard asHttpLink(trimmed) == nil else { return nil }
        guard plain.utf8.count <= 750_000 else { return nil }
        let markdown = BookmarkShareMarkdownPreface.prefixedNoteMarkdown(body: trimmed)
        return .noteMarkdown(markdown: markdown)
    }

    // MARK: NSItemProvider helpers

    private static func loadURLObject(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    private static func loadItem(from provider: NSItemProvider, typeIdentifier: String) async -> NSSecureCoding? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    private static func loadData(from provider: NSItemProvider, type: UTType) async -> Data? {
        guard provider.hasItemConformingToTypeIdentifier(type.identifier) else { return nil }
        guard let item = await loadItem(from: provider, typeIdentifier: type.identifier) else { return nil }
        return coerceData(item)
    }

    private static func loadPlainText(from provider: NSItemProvider) async -> String? {
        let plainIds = prioritizedTypeIds([UTType.plainText.identifier, "public.plain-text"], provider: provider)
        for typeId in plainIds {
            guard let item = await loadItem(from: provider, typeIdentifier: typeId) else { continue }
            if let text = coerceString(item), !text.isEmpty {
                return text
            }
        }
        return nil
    }

    private static func loadFileURL(from provider: NSItemProvider) async -> URL? {
        let ids = prioritizedTypeIds([UTType.fileURL.identifier, "public.file-url"], provider: provider)
        for typeId in ids {
            guard let item = await loadItem(from: provider, typeIdentifier: typeId),
                  let url = coerceURL(item),
                  url.isFileURL
            else { continue }
            return url
        }
        return nil
    }

    private static func coerceData(_ item: NSSecureCoding) -> Data? {
        if let data = item as? Data { return data }
        if let url = coerceURL(item), url.isFileURL { return secureRead(url) }
        if let text = coerceString(item) { return text.data(using: .utf8) }
        return nil
    }

    private static func coerceString(_ item: NSSecureCoding) -> String? {
        if let string = item as? String { return string }
        if let string = item as? NSString { return string as String }
        return nil
    }

    private static func coerceURL(_ item: NSSecureCoding) -> URL? {
        if let url = item as? URL { return url }
        if let url = item as? NSURL { return url as URL }
        if let text = coerceString(item) { return URL(string: text) }
        return nil
    }

    private static func secureRead(_ url: URL) -> Data? {
        let secured = url.startAccessingSecurityScopedResource()
        defer {
            if secured { url.stopAccessingSecurityScopedResource() }
        }
        return try? Data(contentsOf: url)
    }

    private static func fileExtension(from suggestedName: String?) -> String? {
        guard let suggestedName, !suggestedName.isEmpty else { return nil }
        let ext = URL(fileURLWithPath: suggestedName).pathExtension.lowercased()
        return ext.isEmpty ? nil : ext
    }

    private static func prioritizedTypeIds(_ preferred: [String], provider: NSItemProvider) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for id in preferred where provider.hasItemConformingToTypeIdentifier(id) {
            if seen.insert(id).inserted { ordered.append(id) }
        }
        for id in provider.registeredTypeIdentifiers {
            if seen.insert(id).inserted { ordered.append(id) }
        }
        return ordered
    }

    private static func dedupe(_ types: [UTType]) -> [UTType] {
        var seen = Set<String>()
        var output: [UTType] = []
        for type in types where seen.insert(type.identifier).inserted {
            output.append(type)
        }
        return output
    }
}
