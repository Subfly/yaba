//
//  MediamarkCreationContent.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftUI

struct MediamarkCreationContent: View {
    let mediaMarkType: MediaMarkType
    let preselectedFolderId: String?
    let preselectedTagIds: [String]
    let editingBookmarkId: String?
    let initialSharePayload: BookmarkShareIncomingPayload?
    let locksImportedPrimaryPayload: Bool
    let onDone: () -> Void

    init(
        mediaMarkType: MediaMarkType,
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        editingBookmarkId: String?,
        initialSharePayload: BookmarkShareIncomingPayload? = nil,
        locksImportedPrimaryPayload: Bool = false,
        onDone: @escaping () -> Void
    ) {
        self.mediaMarkType = mediaMarkType
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.editingBookmarkId = editingBookmarkId
        self.initialSharePayload = initialSharePayload
        self.locksImportedPrimaryPayload = locksImportedPrimaryPayload
        self.onDone = onDone
    }

    var body: some View {
        switch mediaMarkType {
        case .image:
            ImagemarkCreationContent(
                preselectedFolderId: preselectedFolderId,
                preselectedTagIds: preselectedTagIds,
                editingBookmarkId: editingBookmarkId,
                initialSharePayload: initialSharePayload,
                locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                onDone: onDone
            )
        case .video:
            VideomarkCreationContent(
                preselectedFolderId: preselectedFolderId,
                preselectedTagIds: preselectedTagIds,
                editingBookmarkId: editingBookmarkId,
                initialSharePayload: initialSharePayload,
                locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                onDone: onDone
            )
        case .audio:
            AudiomarkCreationContent(
                preselectedFolderId: preselectedFolderId,
                preselectedTagIds: preselectedTagIds,
                editingBookmarkId: editingBookmarkId,
                initialSharePayload: initialSharePayload,
                locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                onDone: onDone
            )
        }
    }
}
