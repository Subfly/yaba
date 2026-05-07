//
//  MediamarkManager.swift
//  YABACore
//
//  Media bookmark subtype (`MediaBookmarkModel`). Compose `ImagemarkManager` parity.
//

import Foundation
import SwiftData

/// Image bytes + label for sharing or exporting a mediamark bookmark (image subtype).
public struct MediamarkExportPayload: Sendable {
    public let imageData: Data
    public let label: String

    public init(imageData: Data, label: String) {
        self.imageData = imageData
        self.label = label
    }
}

public enum MediamarkManager {
    public static func queueCreateOrUpdateMediaDetails(
        bookmarkId: String,
        originalData: Data? = nil,
        mediaMarkType: MediaMarkType? = nil
    ) {
        CoreOperationQueue.shared.queue(name: "CreateOrUpdateMediaDetails:\(bookmarkId)") { context in
            try upsertMediaDetails(
                bookmarkId: bookmarkId,
                originalData: originalData,
                mediaMarkType: mediaMarkType,
                context: context
            )
        }
    }

    private static func upsertMediaDetails(
        bookmarkId: String,
        originalData: Data?,
        mediaMarkType: MediaMarkType?,
        context: ModelContext
    ) throws {
        guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
            return
        }
        let row: MediaBookmarkModel
        if let existing = bookmark.mediaDetail {
            row = existing
        } else {
            let inserted = MediaBookmarkModel(
                mediaMarkTypeRaw: mediaMarkType?.rawValue ?? MediaMarkType.image.rawValue,
                originalData: originalData,
                bookmark: bookmark
            )
            context.insert(inserted)
            bookmark.mediaDetail = inserted
            row = inserted
        }
        if let mediaMarkType {
            row.mediaMarkTypeRaw = mediaMarkType.rawValue
        }
        if let originalData {
            row.originalData = originalData
        }
        bookmark.editedAt = .now
    }

    /// Loads image bytes and label for share / save-to-photos flows (image subtype).
    public static func fetchExportPayload(bookmarkId: String) async throws -> MediamarkExportPayload? {
        try await withCheckedThrowingContinuation { cont in
            var result: MediamarkExportPayload?
            CoreOperationQueue.shared.queue(name: "MediamarkExportPayload:\(bookmarkId)") { context in
                guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
                    result = nil
                    return
                }
                let data = bookmark.mediaDetail?.originalData ?? bookmark.imagePayload?.bytes
                guard let data, !data.isEmpty else {
                    result = nil
                    return
                }
                result = MediamarkExportPayload(imageData: data, label: bookmark.label)
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
