//
//  BookmarkKindCreationSheet.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftUI

struct BookmarkKindCreationSheet: View {
    let launch: BookmarkKindFormLaunch
    let onDone: () -> Void
    var onCloseRequest: (() -> Void)? = nil
    var onNoteCreatedNavigate: ((String) -> Void)? = nil

    var body: some View {
        NavigationStack {
            BookmarkKindForm(
                mode: .create(
                    launch.kind,
                    preselectedFolderId: launch.preselectedFolderId,
                    preselectedTagIds: launch.preselectedTagIds,
                    mediaMarkType: launch.mediaMarkType,
                    docmarkType: launch.docmarkType,
                    initialSharePayload: launch.initialSharePayload,
                    locksImportedPrimaryPayload: launch.locksImportedPrimaryPayload
                ),
                onDone: onDone,
                onNoteCreatedNavigate: onNoteCreatedNavigate
            )
        }
        .environment(\.bookmarkCreationOnCloseRequest, onCloseRequest)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

private struct BookmarkCreationOnCloseRequestKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    /// When non-nil (set by ``BookmarkKindCreationSheet`` hosts like share extensions), Cancel should call this instead of ``DismissAction``.
    var bookmarkCreationOnCloseRequest: (() -> Void)? {
        get { self[BookmarkCreationOnCloseRequestKey.self] }
        set { self[BookmarkCreationOnCloseRequestKey.self] = newValue }
    }
}
