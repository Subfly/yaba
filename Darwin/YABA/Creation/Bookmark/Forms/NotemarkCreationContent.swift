//
//  NotemarkCreationContent.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftData
import SwiftUI

struct NotemarkCreationContent: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.bookmarkCreationOnCloseRequest)
    private var bookmarkCreationOnCloseRequest

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var machine = NotemarkCreationStateMachine()

    @State
    private var showFolderSheet = false

    @State
    private var showTagSheet = false

    @State
    private var previewContentAppearance: PreviewContentAppearance = .list

    let preselectedFolderId: String?
    let preselectedTagIds: [String]
    let editingBookmarkId: String?
    let initialMarkdown: String?
    let onDone: () -> Void
    /// Invoked after a successful **new** note save, before the sheet dismisses.
    var onCreatedBookmarkId: ((String) -> Void)? = nil

    @State
    private var didApplyInitialMarkdown = false

    init(
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        editingBookmarkId: String?,
        initialMarkdown: String? = nil,
        onDone: @escaping () -> Void,
        onCreatedBookmarkId: ((String) -> Void)? = nil
    ) {
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.editingBookmarkId = editingBookmarkId
        self.initialMarkdown = initialMarkdown
        self.onDone = onDone
        self.onCreatedBookmarkId = onCreatedBookmarkId
        _machine = State(initialValue: NotemarkCreationStateMachine())
        _showFolderSheet = State(initialValue: false)
        _showTagSheet = State(initialValue: false)
        _previewContentAppearance = State(initialValue: .list)
        _didApplyInitialMarkdown = State(initialValue: false)
    }

    private var isEditing: Bool {
        editingBookmarkId != nil
    }

    var body: some View {
        NavigationStack {
            BookmarkCreationFolderVisuals(
                folderId: machine.state.selectedFolderId,
                uncategorizedCreationRequired: machine.state.uncategorizedFolderCreationRequired
            ) { folderForPresentation, mainTint in
                ZStack {
                    AnimatedGradient(color: mainTint)
                    formList(
                        mainTint: mainTint,
                        folderForPresentation: folderForPresentation
                    )
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
            syncPreviewAppearanceFromMachine()
        }
    }

    private func formList(
        mainTint: Color,
        folderForPresentation: FolderModel?
    ) -> some View {
        List {
            Section {
                BookmarkCreationBookmarkPreviewContent(
                    previewContentAppearance: previewContentAppearance,
                    imageData: nil,
                    fallbackIcon: "note-edit",
                    mainTint: mainTint,
                    label: machine.state.label,
                    bookmarkDescription: machine.state.bookmarkDescription,
                    bigCardImageHeight: 160
                )
                    .bookmarkCreationPreviewListRowBackground(appearance: previewContentAppearance)
            } header: {
                BookmarkCreationPreviewHeader(
                    previewContentAppearance: $previewContentAppearance,
                    mainTint: mainTint
                )
            }

            Section {
                BookmarkCreationPinnedTitleDescriptionFields(
                    mainTint: mainTint,
                    label: labelBinding,
                    bookmarkDescription: descriptionBinding,
                    isPinned: isPinnedBinding,
                    pinIconBundleKey: machine.state.isPinned ? "pin" : "pin-off"
                )
            } header: {
                BookmarkCreationInfoSectionHeaderBuilders.infoHeader()
            }

            BookmarkFormFolderTagRows(
                folderForPresentation: folderForPresentation,
                selectedTagIds: machine.state.selectedTagIds,
                onFolderNavigate: { showFolderSheet = true },
                onTagsNavigate: { showTagSheet = true }
            )

            BookmarkCreationLastErrorSection(message: machine.state.lastError)
        }
        .bookmarkCreationFormListModifiers(mainTint: mainTint)
        .navigationTitle(
            LocalizedStringKey(isEditing ? "Edit Bookmark Title" : "Create Bookmark Title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    BookmarkCreationDismiss.perform(
                        bookmarkCreationOnCloseRequest: bookmarkCreationOnCloseRequest,
                        dismiss: dismiss
                    )
                } label: {
                    Text("Cancel")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await machine.send(.onSave)
                        guard machine.state.lastError == nil else { return }
                        let createdId = machine.state.pendingSavedBookmarkId
                        onDone()
                        if let createdId {
                            DispatchQueue.main.async {
                                onCreatedBookmarkId?(createdId)
                            }
                        }
                    }
                } label: {
                    Text("Done")
                }
                .disabled(machine.state.isSaving || machine.state.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var labelBinding: Binding<String> {
        Binding(
            get: { machine.state.label },
            set: { newValue in
                Task {
                    await machine.send(.onChangeLabel(newValue))
                }
            }
        )
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { machine.state.bookmarkDescription },
            set: { newValue in
                Task {
                    await machine.send(.onChangeDescription(newValue))
                }
            }
        )
    }

    private var isPinnedBinding: Binding<Bool> {
        Binding(
            get: { machine.state.isPinned },
            set: { newValue in
                guard newValue != machine.state.isPinned else { return }
                Task { await machine.send(.onTogglePinned) }
            }
        )
    }

    private func syncPreviewAppearanceFromMachine() {
        previewContentAppearance = BookmarkCreationPreviewAppearanceMapping.previewContentAppearance(
            bookmarkAppearance: machine.state.bookmarkAppearance,
            cardImageSizing: machine.state.cardImageSizing
        )
    }

    private func bootstrap() async {
        if let bid = editingBookmarkId,
           let bookmark = BookmarkFlowHydration.fetchBookmark(bookmarkId: bid, modelContext: modelContext)
        {
            machine.replaceState(BookmarkFlowHydration.notemarkUIState(from: bookmark))
            return
        }
        let resolved = BookmarkCreationFolderResolution.resolveForNewBookmark(
            modelContext: modelContext,
            preselectedFolderId: preselectedFolderId
        )
        await machine.send(
            .onInit(
                notemarkId: nil,
                initialFolderId: resolved.selectedFolderId,
                initialTagIds: preselectedTagIds,
                uncategorizedFolderCreationRequired: resolved.uncategorizedFolderCreationRequired
            )
        )

        guard editingBookmarkId == nil, !didApplyInitialMarkdown else { return }
        guard let initialMarkdown, !initialMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        didApplyInitialMarkdown = true
        await machine.send(.onChangeDocument(initialMarkdown))
    }
}
