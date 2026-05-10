//
//  EPUBCoverExtractor.swift
//  YABACore
//
//  Reads EPUB cover image bytes only (bookmark preview): marmelroy/Zip unpacks (EPUB is ZIP),
//  SwiftSoup parses ``container.xml`` and OPF (same stack as ``LinkMetadataExtractor``).
//

import Foundation
import SwiftSoup
import Zip

public enum EPUBCoverExtractor {

    /// Raw cover bitmap bytes referenced from the EPUB manifest, when ``container.xml`` + OPF resolve cleanly.
    public static func coverImageData(from epubData: Data) -> Data? {
        guard !epubData.isEmpty else { return nil }

        let fm = FileManager.default
        let id = UUID().uuidString
        let base = fm.temporaryDirectory
        /// ``Zip`` only whitelists ``.zip`` / ``.cbz`` unless extended; EPUB payloads are ZIP, so `.zip` is sufficient.
        let archiveURL = base.appendingPathComponent("yaba-epub-\(id).zip", isDirectory: false)
        let unpackURL = base.appendingPathComponent("yaba-epub-unpack-\(id)", isDirectory: true)

        do {
            try epubData.write(to: archiveURL, options: .atomic)
            try fm.createDirectory(at: unpackURL, withIntermediateDirectories: true)
            try Zip.unzipFile(archiveURL, destination: unpackURL, overwrite: true, password: nil, progress: nil)
        } catch {
            try? fm.removeItem(at: archiveURL)
            try? fm.removeItem(at: unpackURL)
            return nil
        }

        defer {
            try? fm.removeItem(at: archiveURL)
            try? fm.removeItem(at: unpackURL)
        }

        let fileIndex = EpubUnpackedIndex.build(root: unpackURL)

        guard let containerXML = EpubUnpackedIndex.data(forLogicalPath: "META-INF/container.xml", index: fileIndex),
              let opfZIPPath = EpubContainerXml.packagePath(fromUTF8XML: containerXML),
              let packageXML = EpubUnpackedIndex.data(forLogicalPath: opfZIPPath, index: fileIndex),
              let coverHrefRaw = EpubOpfCover.hrefRelativeToPackage(fromUTF8XML: packageXML)
        else { return nil }

        let href = EpubPath.decodePercentEscaped(coverHrefRaw)
        guard href.isEmpty == false else { return nil }

        let coverZIPPath = EpubPath.resolve(opfZIPPath: opfZIPPath, hrefRelativeToOpf: href)
        return EpubUnpackedIndex.data(forLogicalPath: coverZIPPath, index: fileIndex)
    }
}

// MARK: - Unpacked tree (case-normalized path keys)

private enum EpubUnpackedIndex {

    static func build(root: URL) -> [String: URL] {
        let fm = FileManager.default
        var map: [String: URL] = [:]
        map.reserveCapacity(64)

        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return map }

        let rootPath = root.standardizedFileURL.path
        let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"

        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else { continue }

            let path = fileURL.standardizedFileURL.path
            guard path.hasPrefix(rootPrefix), path.count > rootPrefix.count else { continue }

            let relative = String(path.dropFirst(rootPrefix.count))
            let key = normalizePathKey(relative)
            if map[key] == nil {
                map[key] = fileURL
            }
        }

        return map
    }

    static func data(forLogicalPath logical: String, index: [String: URL]) -> Data? {
        let key = normalizePathKey(logical)
        guard let url = index[key] else { return nil }
        return try? Data(contentsOf: url)
    }

    private static func normalizePathKey(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\\", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/")
            .filter { $0 != "." }
            .joined(separator: "/")
            .lowercased()
    }
}

// MARK: - Parser bootstrap

private enum EpubXml {
    static func document(_ data: Data) -> Document? {
        guard let s = String(data: data, encoding: .utf8) else { return nil }
        return document(s)
    }

    static func document(_ string: String) -> Document? {
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.isEmpty == false else { return nil }
        return try? Parser.parse(t, "")
    }

    static func localTagName(_ el: Element) -> String {
        let raw = el.tagName().trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let ix = raw.lastIndex(of: ":") {
            return String(raw[raw.index(after: ix)...])
        }
        return raw
    }

    /// SwiftSoup tree queries like ``getElementsByTag`` / ``getAllElements`` are throwing.
    fileprivate static func allElements(in doc: Document) -> [Element] {
        (try? doc.getAllElements())?.array() ?? []
    }

    fileprivate static func firstElement(tagName: String, in doc: Document) -> Element? {
        (try? doc.getElementsByTag(tagName))?.first()
    }

    static func manifest(_ doc: Document) -> Element? {
        if let m = firstElement(tagName: "manifest", in: doc) {
            return m
        }
        return allElements(in: doc).first { Self.localTagName($0) == "manifest" }
    }

    static func manifestItemElements(_ manifest: Element) -> [Element] {
        manifest.children().array().filter { Self.localTagName($0) == "item" }
    }

    /// ``meta`` elements anywhere in package (typically under `<metadata>`).
    static func metaElements(_ doc: Document) -> [Element] {
        allElements(in: doc).filter { Self.localTagName($0) == "meta" }
    }

    /// ``Element.attr(_:)`` is throwing in SwiftSoup; missing keys behave like absent attributes.
    static func attributes(_ keys: String..., element: Element) -> String {
        keys
            .compactMap { key in
                guard let raw = try? element.attr(key) else { return nil }
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            }
            .first { !$0.isEmpty } ?? ""
    }
}

// MARK: - META-INF/container.xml

private enum EpubContainerXml {

    /// Returns ZIP-relative UTF-8 path to the OPF (package document).
    static func packagePath(fromUTF8XML data: Data) -> String? {
        guard let doc = EpubXml.document(data) else { return nil }

        if let rf = EpubXml.firstElement(tagName: "rootfile", in: doc),
           let path = normalizedZIPPath(attributes("full-path", element: rf)) {
            return path
        }

        for el in EpubXml.allElements(in: doc) {
            guard EpubXml.localTagName(el) == "rootfile" else { continue }
            if let decoded = normalizedZIPPath(attributes("full-path", element: el)) {
                return decoded
            }
        }

        let anyFullPath = EpubXml.allElements(in: doc).compactMap { el -> String? in
            let fp = EpubXml.attributes("full-path", element: el)
            guard fp.isEmpty == false else { return nil }
            return normalizedZIPPath(fp)
        }
        return anyFullPath.first
    }

    private static func normalizedZIPPath(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return EpubPath.decodePercentEscaped(trimmed)
    }

    private static func attributes(_ key: String, element el: Element) -> String {
        EpubXml.attributes(key, element: el)
    }
}

// MARK: - OPF cover href (relative to package file folder)

private enum EpubOpfCover {

    enum Strategy: CaseIterable {
        case epubThreeCoverProperty
        case epubTwoMetaCover
        case guideCoverReference
    }

    /// First matching cover ``href`` as stored in manifest / guide metadata.
    static func hrefRelativeToPackage(fromUTF8XML data: Data) -> String? {
        guard let doc = EpubXml.document(data),
              let manifest = EpubXml.manifest(doc)
        else { return nil }

        let items = EpubXml.manifestItemElements(manifest)

        for step in Strategy.allCases {
            switch step {
            case .epubThreeCoverProperty:
                if let href = hrefFromCoverProperty(items) { return href }
            case .epubTwoMetaCover:
                if let href = hrefFromLegacyMetaCover(doc: doc, items: items) { return href }
            case .guideCoverReference:
                if let href = hrefFromGuideCover(doc: doc) { return href }
            }
        }

        return nil
    }

    private static func hrefFromCoverProperty(_ items: [Element]) -> String? {
        for item in items {
            let props = EpubXml.attributes("properties", element: item).lowercased()
            let tokens = props.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard tokens.contains("cover-image") else {
                continue
            }
            let href = EpubXml.attributes("href", element: item)
            guard href.isEmpty == false else {
                continue
            }
            return href
        }
        return nil
    }

    private static func hrefFromLegacyMetaCover(doc: Document, items: [Element]) -> String? {
        for meta in EpubXml.metaElements(doc) {
            let name = EpubXml.attributes("name", element: meta).lowercased()
            guard name == "cover" else {
                continue
            }
            let referencedId = EpubXml.attributes("content", element: meta)
            guard referencedId.isEmpty == false else {
                continue
            }

            guard let matched = items.first(where: {
                EpubXml.attributes("id", element: $0).caseInsensitiveCompare(referencedId) == .orderedSame
            }) else {
                continue
            }
            let href = EpubXml.attributes("href", element: matched)
            guard href.isEmpty == false else {
                continue
            }
            return href
        }

        return nil
    }

    private static func hrefFromGuideCover(doc: Document) -> String? {
        for reference in EpubXml.allElements(in: doc) where EpubXml.localTagName(reference) == "reference" {
            let kind = EpubXml.attributes("type", "opf:type", element: reference).lowercased()
            guard kind == "cover" else {
                continue
            }
            let href = EpubXml.attributes("href", "opf:href", element: reference)
            guard href.isEmpty == false else {
                continue
            }
            return href
        }
        return nil
    }
}

// MARK: - Path resolution

private enum EpubPath {

    static func decodePercentEscaped(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t.removingPercentEncoding ?? t).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Resolves ``href`` (relative to the OPF ZIP path, e.g. ``OEBPS/content.opf``).
    static func resolve(opfZIPPath: String, hrefRelativeToOpf: String) -> String {
        let opfClean = forwardSlashes(opfZIPPath.trimmingCharacters(in: .whitespacesAndNewlines))
        let hrefTrimmed = forwardSlashes(hrefRelativeToOpf.trimmingCharacters(in: .whitespacesAndNewlines))
        guard hrefTrimmed.isEmpty == false else {
            return stripLeadingSlash(opfClean)
        }

        if hrefTrimmed.hasPrefix("/") {
            return stripLeadingSlash(hrefTrimmed)
        }

        let opfDirPieces: [String]
        if let idx = opfClean.lastIndex(of: "/") {
            let folder = String(opfClean[..<idx])
            opfDirPieces = folder.isEmpty ? [] : folder.split(separator: "/").map(String.init)
        } else {
            opfDirPieces = []
        }

        var stack = opfDirPieces
        stack.reserveCapacity(opfDirPieces.count + 8)

        for component in hrefTrimmed.split(separator: "/", omittingEmptySubsequences: false) where component.isEmpty == false {
            switch component {
            case "..":
                if !stack.isEmpty { stack.removeLast() }
            case ".":
                break
            default:
                stack.append(String(component))
            }
        }

        return stack.joined(separator: "/")
    }

    private static func forwardSlashes(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "/")
    }

    private static func stripLeadingSlash(_ s: String) -> String {
        String(s.drop { $0 == "/" })
    }
}
