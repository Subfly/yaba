//
//  BookmarkShareIncomingPayload.swift
//  YABA
//
//  Describes the first item resolved from an extension activity / share intent.
//

import Foundation

/// Payload extracted from ``NSExtensionItem`` / ``NSItemProvider`` for share targets.
///
/// Stored on ``BookmarkKindFormLaunch.initialSharePayload`` and consumed during creation bootstrap.
enum BookmarkShareIncomingPayload: Equatable {
    /// HTTP(S) link string.
    case link(String)

    /// File-backed bookmark document (PDF, CSV, EPUB).
    case document(Data, fileName: String?, DocmarkType)

    /// Imported image bytes.
    case image(Data, fileExtension: String)

    /// Imported audio bytes.
    case audio(Data, fileExtension: String)

    /// Imported video bytes; optional thumbnail PNG/JPEG extracted when possible.
    case video(Data, thumbnailData: Data?, fileExtension: String)

    /// Prefilled Markdown body for ``NotemarkCreationContent``.
    ///
    /// Do not derive bookmark title or description from share input; only seeds note document text.
    case noteMarkdown(markdown: String)
}
