//
//  DocmarkManager.swift
//  YABACore
//
//  Document bookmark subtype (`DocBookmarkModel`). Compose `DocmarkManager` parity.
//

import Foundation
import SwiftData

/// Document bytes + label for share / save-copy flows (`pdf`, `csv`, …).
public struct DocmarkExportPayload: Sendable {
    public let documentBytes: Data
    public let label: String
    public let pathExtension: String

    public init(documentBytes: Data, label: String, pathExtension: String) {
        self.documentBytes = documentBytes
        self.label = label
        self.pathExtension = pathExtension
    }
}

public enum DocmarkManager {
    /// Ensures a `DocBookmarkModel` row exists after base bookmark creation (empty metadata).
    public static func queueEnsureInitialDocDetail(bookmarkId: String) {
        CoreOperationQueue.shared.queue(name: "EnsureInitialDocDetail:\(bookmarkId)") { context in
            try upsertDocDetails(
                bookmarkId: bookmarkId,
                summary: nil,
                docmarkType: nil,
                context: context
            )
        }
    }

    public static func queueCreateOrUpdateDocDetails(
        bookmarkId: String,
        summary: String? = nil,
        docmarkType: DocmarkType? = nil
    ) {
        CoreOperationQueue.shared.queue(name: "CreateOrUpdateDocDetails:\(bookmarkId)") { context in
            try upsertDocDetails(
                bookmarkId: bookmarkId,
                summary: summary,
                docmarkType: docmarkType,
                context: context
            )
        }
    }

    /// Persists original PDF bytes on the doc bookmark payload
    public static func queueUpsertDocBookmarkPayloadBytes(bookmarkId: String, documentBytes: Data) {
        CoreOperationQueue.shared.queue(name: "UpsertDocBookmarkPayload:\(bookmarkId)") { context in
            guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
                return
            }
            let row: DocBookmarkModel
            if let existing = bookmark.docDetail {
                row = existing
            } else {
                let inserted = DocBookmarkModel(bookmark: bookmark)
                context.insert(inserted)
                bookmark.docDetail = inserted
                row = inserted
            }
            if let payload = row.payload {
                payload.bytes = documentBytes
            } else {
                let payload = DocBookmarkPayloadModel(bytes: documentBytes, docBookmark: row)
                context.insert(payload)
                row.payload = payload
            }
            bookmark.docmarkTypeRaw = row.docmarkTypeRaw
            bookmark.editedAt = .now
        }
    }

    private static func upsertDocDetails(
        bookmarkId: String,
        summary: String?,
        docmarkType: DocmarkType?,
        context: ModelContext
    ) throws {
        guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
            return
        }
        let row: DocBookmarkModel
        if let existing = bookmark.docDetail {
            row = existing
        } else {
            let inserted = DocBookmarkModel(bookmark: bookmark)
            context.insert(inserted)
            bookmark.docDetail = inserted
            row = inserted
        }
        if let summary { row.summary = summary.nilIfEmpty }
        if let docmarkType { row.docmarkTypeRaw = docmarkType.rawValue }
        bookmark.docmarkTypeRaw = row.docmarkTypeRaw
        bookmark.editedAt = .now
    }

    /// Loads stored PDF bytes and label for share / directory export.
    public static func fetchExportPayload(bookmarkId: String) async throws -> DocmarkExportPayload? {
        try await withCheckedThrowingContinuation { cont in
            var result: DocmarkExportPayload?
            CoreOperationQueue.shared.queue(name: "DocmarkExportPayload:\(bookmarkId)") { context in
                guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
                    result = nil
                    return
                }
                let data = bookmark.docDetail?.payload?.bytes
                guard let data, !data.isEmpty else {
                    result = nil
                    return
                }
                let type = bookmark.docDetail?.docmarkType ?? .pdf
                let ext: String
                switch type {
                case .pdf:
                    ext = "pdf"
                case .csv:
                    ext = "csv"
                case .epub:
                    ext = "epub"
                }
                result = DocmarkExportPayload(documentBytes: data, label: bookmark.label, pathExtension: ext)
            } completion: { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: result)
                }
            }
        }
    }
}
