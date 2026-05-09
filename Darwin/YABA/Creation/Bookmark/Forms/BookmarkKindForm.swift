//
//  BookmarkKindForm.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftUI

struct BookmarkKindForm: View {
    enum Mode {
        case create(
            BookmarkKind,
            preselectedFolderId: String?,
            preselectedTagIds: [String],
            mediaMarkType: MediaMarkType?,
            docmarkType: DocmarkType?,
            initialSharePayload: BookmarkShareIncomingPayload?,
            locksImportedPrimaryPayload: Bool
        )
        case edit(BookmarkModel)
    }

    let mode: Mode
    let onDone: () -> Void
    var onNoteCreatedNavigate: ((String) -> Void)? = nil

    var body: some View {
        switch mode {
        case let .create(kind, folderId, tagIds, mediaMarkType, docmarkType, initialSharePayload, locksImportedPrimaryPayload):
            switch kind {
            case .link:
                LinkmarkCreationContent(
                    preselectedFolderId: folderId,
                    preselectedTagIds: tagIds,
                    initialUrl: initialLink(from: initialSharePayload),
                    editingBookmarkId: nil,
                    locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                    onDone: onDone
                )
            case .note:
                NotemarkCreationContent(
                    preselectedFolderId: folderId,
                    preselectedTagIds: tagIds,
                    editingBookmarkId: nil,
                    initialMarkdown: initialNoteMarkdown(from: initialSharePayload),
                    onDone: onDone,
                    onCreatedBookmarkId: onNoteCreatedNavigate
                )
            case .media:
                MediamarkCreationContent(
                    mediaMarkType: mediaMarkType ?? .image,
                    preselectedFolderId: folderId,
                    preselectedTagIds: tagIds,
                    editingBookmarkId: nil,
                    initialSharePayload: initialSharePayload,
                    locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                    onDone: onDone
                )
            case .file:
                DocmarkCreationContent(
                    preselectedFolderId: folderId,
                    preselectedTagIds: tagIds,
                    editingBookmarkId: nil,
                    creationDocmarkKind: docmarkType ?? .pdf,
                    initialSharePayload: initialSharePayload,
                    locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                    onDone: onDone
                )
            }
        case let .edit(bookmark):
            switch bookmark.kind {
            case .link:
                LinkmarkCreationContent(
                    preselectedFolderId: nil,
                    preselectedTagIds: [],
                    initialUrl: nil,
                    editingBookmarkId: bookmark.bookmarkId,
                    locksImportedPrimaryPayload: false,
                    onDone: onDone
                )
            case .note:
                NotemarkCreationContent(
                    preselectedFolderId: nil,
                    preselectedTagIds: [],
                    editingBookmarkId: bookmark.bookmarkId,
                    onDone: onDone
                )
            case .media:
                MediamarkCreationContent(
                    mediaMarkType: bookmark.mediaDetail?.mediaMarkType ?? .image,
                    preselectedFolderId: nil,
                    preselectedTagIds: [],
                    editingBookmarkId: bookmark.bookmarkId,
                    onDone: onDone
                )
            case .file:
                DocmarkCreationContent(
                    preselectedFolderId: nil,
                    preselectedTagIds: [],
                    editingBookmarkId: bookmark.bookmarkId,
                    creationDocmarkKind: bookmark.docDetail?.docmarkType ?? .pdf,
                    onDone: onDone
                )
            }
        }
    }
}

private extension BookmarkKindForm {
    func initialLink(from payload: BookmarkShareIncomingPayload?) -> String? {
        guard case let .link(url) = payload else { return nil }
        return url
    }

    func initialNoteMarkdown(from payload: BookmarkShareIncomingPayload?) -> String? {
        guard case let .noteMarkdown(markdown) = payload else { return nil }
        return markdown
    }
}
