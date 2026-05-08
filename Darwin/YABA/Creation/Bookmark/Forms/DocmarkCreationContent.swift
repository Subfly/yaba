//
//  DocmarkCreationContent.swift
//  YABA
//

import SwiftData
import SwiftUI

struct DocmarkCreationContent: View {
    @Environment(\.modelContext)
    private var modelContext

    @State
    private var machine = DocmarkCreationStateMachine()

    @State
    private var showFolderSheet = false

    @State
    private var showTagSheet = false

    let preselectedFolderId: String?
    let preselectedTagIds: [String]
    let editingBookmarkId: String?
    let creationDocmarkKind: DocmarkType
    let onDone: () -> Void

    init(
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        editingBookmarkId: String?,
        creationDocmarkKind: DocmarkType = .pdf,
        onDone: @escaping () -> Void
    ) {
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.editingBookmarkId = editingBookmarkId
        self.creationDocmarkKind = creationDocmarkKind
        self.onDone = onDone
    }

    private var routedDocmarkKind: DocmarkType {
        if editingBookmarkId != nil {
            machine.state.docmarkType ?? .pdf
        } else {
            creationDocmarkKind
        }
    }

    var body: some View {
        NavigationStack {
            BookmarkCreationFolderVisuals(
                folderId: machine.state.selectedFolderId,
                uncategorizedCreationRequired: machine.state.uncategorizedFolderCreationRequired
            ) { folderForPresentation, mainTint in
                ZStack {
                    AnimatedGradient(color: mainTint)
                    switch routedDocmarkKind {
                    case .csv:
                        CSVDocmarkCreationContent(
                            machine: machine,
                            mainTint: mainTint,
                            folderForPresentation: folderForPresentation,
                            showFolderSheet: $showFolderSheet,
                            showTagSheet: $showTagSheet,
                            editingBookmarkId: editingBookmarkId,
                            onDone: onDone
                        )
                    case .pdf, .epub:
                        PDFDocmarkCreationContent(
                            machine: machine,
                            mainTint: mainTint,
                            folderForPresentation: folderForPresentation,
                            showFolderSheet: $showFolderSheet,
                            showTagSheet: $showTagSheet,
                            editingBookmarkId: editingBookmarkId,
                            onDone: onDone
                        )
                    }
                }
            }
            .id("\(machine.state.selectedFolderId ?? "")-\(machine.state.uncategorizedFolderCreationRequired)")
        }
        .bookmarkFolderAndTagSheets(
            showFolderSheet: $showFolderSheet,
            showTagSheet: $showTagSheet,
            tagSelectionInitialIds: machine.state.selectedTagIds,
            onFolderPicked: { folderId in
                Task {
                    await machine.send(.onSelectFolderId(folderId))
                }
            },
            onTagsPicked: { ids in
                Task {
                    await machine.send(.onSelectTagIds(ids))
                }
            }
        )
        .task(id: editingBookmarkId) {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        if let bid = editingBookmarkId,
           let bookmark = BookmarkFlowHydration.fetchBookmark(bookmarkId: bid, modelContext: modelContext)
        {
            machine.replaceState(BookmarkFlowHydration.docmarkUIState(from: bookmark))
            return
        }
        let resolved = BookmarkCreationFolderResolution.resolveForNewBookmark(
            modelContext: modelContext,
            preselectedFolderId: preselectedFolderId
        )
        await machine.send(
            .onInit(
                docmarkId: nil,
                initialFolderId: resolved.selectedFolderId,
                initialTagIds: preselectedTagIds,
                uncategorizedFolderCreationRequired: resolved.uncategorizedFolderCreationRequired,
                creationDocmarkKind: creationDocmarkKind
            )
        )
    }
}
