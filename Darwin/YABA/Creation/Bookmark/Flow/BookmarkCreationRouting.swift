//
//  BookmarkCreationRouting.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import Foundation
import SwiftUI

struct BookmarkTypeSelectionContext: Identifiable, Equatable {
    let id: UUID
    let preselectedFolderId: String?
    let preselectedTagIds: [String]

    init(
        id: UUID = UUID(),
        preselectedFolderId: String? = nil,
        preselectedTagIds: [String] = []
    ) {
        self.id = id
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
    }
}

struct BookmarkKindFormLaunch: Identifiable, Equatable {
    let id: UUID
    let kind: BookmarkKind
    let preselectedFolderId: String?
    let preselectedTagIds: [String]
    let mediaMarkType: MediaMarkType?

    init(
        id: UUID = UUID(),
        kind: BookmarkKind,
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        mediaMarkType: MediaMarkType? = nil
    ) {
        self.id = id
        self.kind = kind
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.mediaMarkType = mediaMarkType
    }
}

struct BookmarkCreateTwoStepSheetsModifier: ViewModifier {
    @Binding
    var typeSelection: BookmarkTypeSelectionContext?

    var onCreatedBookmarkNavigate: ((String) -> Void)? = nil

    @State
    private var kindLaunch: BookmarkKindFormLaunch?

    @State
    private var pendingKindAfterTypeDismiss: BookmarkKindFormLaunch?

    func body(content: Content) -> some View {
        content
            .sheet(
                item: $typeSelection,
                onDismiss: {
                    if let next = pendingKindAfterTypeDismiss {
                        kindLaunch = next
                        pendingKindAfterTypeDismiss = nil
                    }
                }
            ) { ctx in
                BookmarkRouteSelectionContent(
                    onCancel: {
                        pendingKindAfterTypeDismiss = nil
                        typeSelection = nil
                    },
                    onSelectKind: { kind, mediaSubtype in
                        pendingKindAfterTypeDismiss = BookmarkKindFormLaunch(
                            kind: kind,
                            preselectedFolderId: ctx.preselectedFolderId,
                            preselectedTagIds: ctx.preselectedTagIds,
                            mediaMarkType: mediaSubtype
                        )
                        typeSelection = nil
                    }
                )
                .presentationDetents([.fraction(0.4), .fraction(0.8)])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $kindLaunch) { launch in
                BookmarkKindCreationSheet(launch: launch, onDone: {
                    kindLaunch = nil
                }, onNoteCreatedNavigate: onCreatedBookmarkNavigate)
            }
    }
}

extension View {
    func bookmarkCreateTwoStepSheets(
        typeSelection: Binding<BookmarkTypeSelectionContext?>,
        onCreatedBookmarkNavigate: ((String) -> Void)? = nil
    ) -> some View {
        modifier(BookmarkCreateTwoStepSheetsModifier(
            typeSelection: typeSelection,
            onCreatedBookmarkNavigate: onCreatedBookmarkNavigate
        ))
    }
}
