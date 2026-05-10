//
//  MediamarkManager.swift
//  YABACore
//
//  Media bookmark subtype (`MediaBookmarkModel`). Compose `ImagemarkManager` parity.
//

import Foundation
import SwiftData

/// Media bytes + label for sharing or exporting a mediamark bookmark (image or video subtype).
public struct MediamarkExportPayload: Sendable {
    public let mediaData: Data
    public let label: String
    public let fileExtension: String
    public let mediaMarkType: MediaMarkType

    public init(mediaData: Data, label: String, fileExtension: String, mediaMarkType: MediaMarkType) {
        self.mediaData = mediaData
        self.label = label
        self.fileExtension = fileExtension
        self.mediaMarkType = mediaMarkType
    }
}

public enum MediamarkManager {
    public static func inferAudioFileExtension(from data: Data) -> String {
        guard !data.isEmpty else { return "wav" }
        if hasPrefix(data, ascii: "fLaC") {
            return "flac"
        }
        if data.count >= 12,
           hasPrefix(data, ascii: "RIFF"),
           hasBytes(data, offset: 8, ascii: "WAVE")
        {
            return "wav"
        }
        if hasPrefix(data, ascii: "ID3") {
            return "mp3"
        }
        if data.count >= 2 {
            let b0 = data[data.startIndex]
            let b1 = data[data.startIndex.advanced(by: 1)]
            if b0 == 0xFF, (b1 & 0xE0) == 0xE0 {
                return "mp3"
            }
        }
        if data.count >= 12, hasBytes(data, offset: 4, ascii: "ftyp") {
            return "m4a"
        }
        return "wav"
    }

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
        bookmark.mediaMarkTypeRaw = row.mediaMarkTypeRaw
        bookmark.editedAt = .now
    }

    /// Loads media bytes and label for share / save-to-photos flows.
    public static func fetchExportPayload(bookmarkId: String) async throws -> MediamarkExportPayload? {
        try await withCheckedThrowingContinuation { cont in
            var result: MediamarkExportPayload?
            CoreOperationQueue.shared.queue(name: "MediamarkExportPayload:\(bookmarkId)") { context in
                guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
                    result = nil
                    return
                }
                let type = bookmark.mediaDetail?.mediaMarkType ?? .image
                let data: Data?
                switch type {
                case .image:
                    data = bookmark.mediaDetail?.originalData ?? bookmark.imagePayload?.bytes
                case .video:
                    data = bookmark.mediaDetail?.originalData
                case .audio:
                    data = bookmark.mediaDetail?.originalData
                }
                guard let data, !data.isEmpty else {
                    result = nil
                    return
                }
                let ext: String
                switch type {
                case .image:
                    ext = "png"
                case .video:
                    ext = "mp4"
                case .audio:
                    ext = inferAudioFileExtension(from: data)
                }
                result = MediamarkExportPayload(
                    mediaData: data,
                    label: bookmark.label,
                    fileExtension: ext,
                    mediaMarkType: type
                )
            } completion: { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: result)
                }
            }
        }
    }

    private static func hasPrefix(_ data: Data, ascii: String) -> Bool {
        guard let bytes = ascii.data(using: .ascii) else { return false }
        guard data.count >= bytes.count else { return false }
        return data.prefix(bytes.count) == bytes
    }

    private static func hasBytes(_ data: Data, offset: Int, ascii: String) -> Bool {
        guard let bytes = ascii.data(using: .ascii) else { return false }
        guard data.count >= offset + bytes.count else { return false }
        let start = data.startIndex.advanced(by: offset)
        let end = start.advanced(by: bytes.count)
        return data[start..<end] == bytes[bytes.startIndex..<bytes.endIndex]
    }
}
