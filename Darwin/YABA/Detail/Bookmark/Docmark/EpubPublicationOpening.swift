//
//  EpubPublicationOpening.swift
//  YABA
//
//  Loads a Readium ``Publication`` from persisted EPUB bytes for in-app reading (main target — Readium linked).
//

import Foundation
import ReadiumShared
import ReadiumStreamer

/// Opens packaged EPUB bytes with Readium for in-app reading (`ReadiumShared` + `ReadiumStreamer`).
@MainActor
enum EpubPublicationOpening {
    /// Returns the opened publication and the temporary `.epub` file URL. Caller must delete the temp file when finished.
    static func openPublication(fromEPUBData data: Data) async -> (publication: Publication, tempFileURL: URL)? {
        guard !data.isEmpty else { return nil }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("yaba-epub-read-\(UUID().uuidString).epub", isDirectory: false)
        do {
            try data.write(to: tempURL, options: .atomic)
        } catch {
            return nil
        }

        guard let fileURL = FileURL(url: tempURL) else {
            try? FileManager.default.removeItem(at: tempURL)
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
            try? FileManager.default.removeItem(at: tempURL)
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
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }

        return (publication, tempURL)
    }
}
