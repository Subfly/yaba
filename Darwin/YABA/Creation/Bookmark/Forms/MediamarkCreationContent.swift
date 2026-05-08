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
    let onDone: () -> Void

    var body: some View {
        switch mediaMarkType {
        case .image:
            ImagemarkCreationContent(
                preselectedFolderId: preselectedFolderId,
                preselectedTagIds: preselectedTagIds,
                editingBookmarkId: editingBookmarkId,
                onDone: onDone
            )
        case .video:
            VideomarkCreationContent(
                preselectedFolderId: preselectedFolderId,
                preselectedTagIds: preselectedTagIds,
                editingBookmarkId: editingBookmarkId,
                onDone: onDone
            )
        case .audio:
            AudiomarkCreationContent(
                preselectedFolderId: preselectedFolderId,
                preselectedTagIds: preselectedTagIds,
                editingBookmarkId: editingBookmarkId,
                onDone: onDone
            )
        }
    }
}
