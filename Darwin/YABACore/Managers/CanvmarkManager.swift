//
//  CanvmarkManager.swift
//  YABACore
//
//  Canvas bookmark subtype (`CanvasBookmarkModel` + payload). Compose `CanvmarkManager` parity.
//

import Foundation
import SwiftData

public enum CanvmarkManager {
    public static func queueSaveCanvasSceneData(
        bookmarkId: String,
        sceneData: Data,
        touchEditedAt: Bool = true
    ) {
        CoreOperationQueue.shared.queue(name: "SaveCanvmarkScene:\(bookmarkId)") { context in
            try saveCanvasSceneInternal(
                bookmarkId: bookmarkId,
                sceneData: sceneData,
                touchEditedAt: touchEditedAt,
                context: context
            )
        }
    }

    public static func queueCreateOrUpdateCanvasDetails(bookmarkId: String) {
        CoreOperationQueue.shared.queue(name: "CreateOrUpdateCanvasDetails:\(bookmarkId)") { context in
            try createOrUpdateCanvasDetailsInternal(bookmarkId: bookmarkId, context: context)
        }
    }

    /// Appends an inline image asset to a canvas bookmark (`CanvasBookmarkModel.inlineAssets`).
    public static func queueAppendCanvasInlineAsset(
        bookmarkId: String,
        assetId: String,
        pathExtension: String,
        bytes: Data,
        completion: ((Error?) -> Void)? = nil
    ) {
        CoreOperationQueue.shared.queue(
            name: "AppendCanvmarkInlineAsset:\(bookmarkId):\(assetId)",
            operation: { context in
                try appendCanvasInlineAssetInternal(
                    bookmarkId: bookmarkId,
                    assetId: assetId,
                    pathExtension: pathExtension,
                    bytes: bytes,
                    context: context
                )
            },
            completion: completion
        )
    }

    /// Removes one inline asset row from a canvas bookmark.
    public static func queueDeleteCanvasInlineAsset(
        bookmarkId: String,
        assetId: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        CoreOperationQueue.shared.queue(
            name: "DeleteCanvmarkInlineAsset:\(bookmarkId):\(assetId)",
            operation: { context in
                try deleteCanvasInlineAssetInternal(
                    bookmarkId: bookmarkId,
                    assetId: assetId,
                    context: context
                )
            },
            completion: completion
        )
    }

    private static func saveCanvasSceneInternal(
        bookmarkId: String,
        sceneData: Data,
        touchEditedAt: Bool,
        context: ModelContext
    ) throws {
        guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
            return
        }
        let canvas = try ensureCanvasDetail(bookmark: bookmark, context: context)
        let payload = try ensureCanvasPayload(canvas: canvas, context: context)
        payload.sceneData = sceneData
        if touchEditedAt {
            bookmark.editedAt = .now
        }
    }

    private static func createOrUpdateCanvasDetailsInternal(bookmarkId: String, context: ModelContext) throws {
        guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
            return
        }
        let canvas = try ensureCanvasDetail(bookmark: bookmark, context: context)
        _ = try ensureCanvasPayload(canvas: canvas, context: context)
        bookmark.editedAt = .now
    }

    private static func ensureCanvasDetail(bookmark: BookmarkModel, context: ModelContext) throws -> CanvasBookmarkModel {
        if let canvas = bookmark.canvasDetail {
            return canvas
        }
        let canvas = CanvasBookmarkModel(bookmark: bookmark)
        context.insert(canvas)
        bookmark.canvasDetail = canvas
        return canvas
    }

    private static func ensureCanvasPayload(canvas: CanvasBookmarkModel, context: ModelContext) throws -> CanvasBookmarkPayloadModel {
        if let payload = canvas.payload {
            return payload
        }
        let payload = CanvasBookmarkPayloadModel(canvasBookmark: canvas)
        context.insert(payload)
        canvas.payload = payload
        return payload
    }

    private static func appendCanvasInlineAssetInternal(
        bookmarkId: String,
        assetId: String,
        pathExtension: String,
        bytes: Data,
        context: ModelContext
    ) throws {
        guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
            return
        }
        guard bookmark.kind == .canvas else { return }
        let canvas = try ensureCanvasDetail(bookmark: bookmark, context: context)
        _ = try ensureCanvasPayload(canvas: canvas, context: context)
        let normalizedExt = normalizeStoredInlineAssetExtension(pathExtension)
        let row = InlineAssetModel(
            assetId: assetId,
            pathExtension: normalizedExt,
            bytes: bytes,
            linkBookmark: nil,
            noteBookmark: nil,
            canvasBookmark: canvas
        )
        context.insert(row)
        canvas.inlineAssets.append(row)
        bookmark.editedAt = .now
    }

    private static func deleteCanvasInlineAssetInternal(
        bookmarkId: String,
        assetId: String,
        context: ModelContext
    ) throws {
        guard let bookmark = try YabaCorePersistenceHelpers.bookmark(bookmarkId: bookmarkId, context: context) else {
            return
        }
        guard bookmark.kind == .canvas, let canvas = bookmark.canvasDetail else { return }
        guard let asset = canvas.inlineAssets.first(where: { $0.assetId == assetId }) else { return }
        context.delete(asset)
        bookmark.editedAt = .now
    }

    private static func normalizeStoredInlineAssetExtension(_ raw: String) -> String {
        let t = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        if t == "jpeg" { return "jpg" }
        if t.isEmpty { return "jpg" }
        return t
    }
}
