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
    let initialSharePayload: BookmarkShareIncomingPayload?
    let locksImportedPrimaryPayload: Bool
    let onDone: () -> Void

    @State
    private var didApplyInitialSharePayload = false

    init(
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        editingBookmarkId: String?,
        creationDocmarkKind: DocmarkType = .pdf,
        initialSharePayload: BookmarkShareIncomingPayload? = nil,
        locksImportedPrimaryPayload: Bool = false,
        onDone: @escaping () -> Void
    ) {
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.editingBookmarkId = editingBookmarkId
        self.creationDocmarkKind = creationDocmarkKind
        self.initialSharePayload = initialSharePayload
        self.locksImportedPrimaryPayload = locksImportedPrimaryPayload
        self.onDone = onDone
        _machine = State(initialValue: DocmarkCreationStateMachine())
        _showFolderSheet = State(initialValue: false)
        _showTagSheet = State(initialValue: false)
        _didApplyInitialSharePayload = State(initialValue: false)
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
                            locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                            onDone: onDone
                        )
                    case .pdf:
                        PDFDocmarkCreationContent(
                            machine: machine,
                            mainTint: mainTint,
                            folderForPresentation: folderForPresentation,
                            showFolderSheet: $showFolderSheet,
                            showTagSheet: $showTagSheet,
                            editingBookmarkId: editingBookmarkId,
                            locksImportedPrimaryPayload: locksImportedPrimaryPayload,
                            onDone: onDone
                        )
                    case .epub:
                        EPUBDocmarkCreationContent(
                            machine: machine,
                            mainTint: mainTint,
                            folderForPresentation: folderForPresentation,
                            showFolderSheet: $showFolderSheet,
                            showTagSheet: $showTagSheet,
                            editingBookmarkId: editingBookmarkId,
                            locksImportedPrimaryPayload: locksImportedPrimaryPayload,
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

        guard editingBookmarkId == nil, !didApplyInitialSharePayload else { return }
        guard case let .document(data, fileName, docmarkType) = initialSharePayload else { return }
        didApplyInitialSharePayload = true
        await machine.send(.onDocumentFromShare(data, sourceFileName: fileName, docmarkType: docmarkType))
    }
}
