//
//  EPUBMetadataExtractor.swift
//  YABACore
//
//  EPUB metadata + cover via Readium Swift Toolkit (linked only from the main YABA app target).
//

import Foundation

#if canImport(ReadiumShared) && canImport(ReadiumStreamer) && canImport(UIKit) && !SHARE_EXTENSION
import ReadiumShared
import ReadiumStreamer
import UIKit

/// Opens packaged EPUB bytes with Readium and extracts Dublin-Core-ish fields plus cover bitmap data.
public enum EPUBMetadataExtractor {
    public static func extract(from data: Data) async -> EpubMetadataResult? {
        guard !data.isEmpty else { return nil }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("yaba-epub-meta-\(UUID().uuidString).epub", isDirectory: false)
        do {
            try data.write(to: tempURL, options: .atomic)
        } catch {
            return nil
        }
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        guard let fileURL = FileURL(url: tempURL) else {
            return nil
        }

        let httpClient = DefaultHTTPClient()
        let assetRetriever = AssetRetriever(httpClient: httpClient)
        let publicationOpener = PublicationOpener(
            parser: DefaultPublicationParser(
                httpClient: httpClient,
                assetRetriever: assetRetriever,
                pdfFactory: DefaultPDFDocumentFactory()
            ),
            contentProtections: []
        )

        let asset: Asset
        switch await assetRetriever.retrieve(url: fileURL) {
        case let .success(a):
            asset = a
        case .failure:
            return nil
        }

        let publication: Publication
        switch await publicationOpener.open(
            asset: asset,
            allowUserInteraction: false,
            sender: nil
        ) {
        case let .success(pub):
            publication = pub
        case .failure:
            return nil
        }

        let md = publication.metadata
        let title = md.title?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let author = md.authors
            .map(\.name)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")
            .nilIfEmpty

        let subject = md.description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        let dateSource = md.published ?? md.modified
        let creationDate = dateSource.map(iso8601String(from:))

        let spineCount = publication.readingOrder.count

        var coverData: Data?
        do {
            let coverImg = try await publication.cover().get()
            coverData = coverImg?.pngData()
        } catch {
            coverData = nil
        }

        return EpubMetadataResult(
            title: title,
            author: author,
            subject: subject,
            creationDate: creationDate,
            spineItemCount: spineCount,
            coverImageData: coverData
        )
    }

    private static func iso8601String(from date: Date) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let primary = iso.string(from: date)
        if !primary.isEmpty {
            return primary
        }
        iso.formatOptions = [.withInternetDateTime]
        return iso.string(from: date)
    }
}

#else

public enum EPUBMetadataExtractor {
    /// Extensions that compile YABACore without Readium cannot extract EPUB metadata.
    /// TODO: FIND ANOTHER WAY FOR EXTRACTING METADATA IN SHARE EXTENSION
    public static func extract(from _: Data) async -> EpubMetadataResult? {
        nil
    }
}

#endif
