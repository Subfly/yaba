//
//  AudiomarkCreationContent.swift
//  YABA
//
//  Audio bookmark creation (file import + custom recorder).
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AudiomarkCreationContent: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.bookmarkCreationOnCloseRequest)
    private var bookmarkCreationOnCloseRequest

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var machine = MediamarkCreationStateMachine()

    @State
    private var showFolderSheet = false

    @State
    private var showTagSheet = false

    @State
    private var showFileImporter = false

    @State
    private var showRecorderSheet = false

    @State
    private var previewContentAppearance: PreviewContentAppearance = .list

    let preselectedFolderId: String?
    let preselectedTagIds: [String]
    let editingBookmarkId: String?
    let initialSharePayload: BookmarkShareIncomingPayload?
    let locksImportedPrimaryPayload: Bool
    let onDone: () -> Void

    @State
    private var didApplyInitialSharePayload = false

    init(
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        editingBookmarkId: String?,
        initialSharePayload: BookmarkShareIncomingPayload? = nil,
        locksImportedPrimaryPayload: Bool = false,
        onDone: @escaping () -> Void
    ) {
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.editingBookmarkId = editingBookmarkId
        self.initialSharePayload = initialSharePayload
        self.locksImportedPrimaryPayload = locksImportedPrimaryPayload
        self.onDone = onDone
        _machine = State(initialValue: MediamarkCreationStateMachine())
        _showFolderSheet = State(initialValue: false)
        _showTagSheet = State(initialValue: false)
        _showFileImporter = State(initialValue: false)
        _showRecorderSheet = State(initialValue: false)
        _previewContentAppearance = State(initialValue: .list)
        _didApplyInitialSharePayload = State(initialValue: false)
    }

    private var isEditing: Bool {
        editingBookmarkId != nil
    }

    private var restrictsPrimaryPayloadUI: Bool {
        isEditing || locksImportedPrimaryPayload
    }

    private static var allowedAudioUTTypes: [UTType] {
        let exts = ["mp3", "wav", "flac", "m4a"]
        let types = exts.compactMap { UTType(filenameExtension: $0) }
        return types.isEmpty ? [.audio] : types
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
                Task { await machine.send(.onSelectFolderId(folderId)) }
            },
            onTagsPicked: { ids in
                Task { await machine.send(.onSelectTagIds(ids)) }
            }
        )
        .task(id: editingBookmarkId) {
            await bootstrap()
            syncPreviewAppearanceFromMachine()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: Self.allowedAudioUTTypes,
            allowsMultipleSelection: false
        ) { result in
            Task {
                guard let url = try? result.get().first else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url), !data.isEmpty else { return }
                let ext = url.pathExtension.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = ext.nilIfEmpty ?? "wav"
                await machine.send(.onAudioPicked(audioData: data, fileExtension: normalized, selectedPath: url.path))
            }
        }
        .sheet(isPresented: $showRecorderSheet) {
            NavigationStack {
                AudioRecorderSheet(
                    onDismiss: { showRecorderSheet = false },
                    onDone: { data, ext, path in
                        Task {
                            await machine.send(.onAudioPicked(audioData: data, fileExtension: ext, selectedPath: path))
                            showRecorderSheet = false
                        }
                    }
                )
            }
            .presentationDetents([.fraction(0.4)])
            #if !targetEnvironment(macCatalyst)
            .presentationDragIndicator(.visible)
            #endif
            .interactiveDismissDisabled()
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
                    fallbackIcon: "audio-wave-01",
                    mainTint: mainTint,
                    label: machine.state.label,
                    bookmarkDescription: machine.state.bookmarkDescription
                )
                    .bookmarkCreationPreviewListRowBackground(appearance: previewContentAppearance)

                if let path = machine.state.selectedFilePath, !path.isEmpty {
                    BookmarkCreationSelectedContentIndicator(path: path, mainTint: mainTint)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                HStack {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label {
                            Text("Select")
                        } icon: {
                            YabaIconView(bundleKey: "add-circle")
                                .frame(width: 24, height: 24)
                        }
                        .bookmarkCreationActionButtonLabelStyle(mainTint: mainTint, isDisabled: restrictsPrimaryPayloadUI)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .disabled(restrictsPrimaryPayloadUI)

                    Button {
                        showRecorderSheet = true
                    } label: {
                        Label {
                            Text("Record")
                        } icon: {
                            YabaIconView(bundleKey: "mic-01")
                                .frame(width: 24, height: 24)
                        }
                        .bookmarkCreationActionButtonLabelStyle(mainTint: mainTint, isDisabled: restrictsPrimaryPayloadUI)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .disabled(restrictsPrimaryPayloadUI)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
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
        .bookmarkCreationFormListModifiers(
            mainTint: mainTint,
            keyboardDismissBehavior: .always
        )
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
                        if machine.state.lastError == nil {
                            onDone()
                        }
                    }
                } label: {
                    Text("Done")
                }
                .disabled(
                    machine.state.isSaving
                        || machine.state.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
    }

    private var labelBinding: Binding<String> {
        Binding(
            get: { machine.state.label },
            set: { newValue in
                Task { await machine.send(.onChangeLabel(newValue)) }
            }
        )
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { machine.state.bookmarkDescription },
            set: { newValue in
                Task { await machine.send(.onChangeDescription(newValue)) }
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
            machine.replaceState(BookmarkFlowHydration.mediamarkUIState(from: bookmark))
            return
        }
        let resolved = BookmarkCreationFolderResolution.resolveForNewBookmark(
            modelContext: modelContext,
            preselectedFolderId: preselectedFolderId
        )
        await machine.send(
            .onInit(
                mediaBookmarkId: nil,
                initialFolderId: resolved.selectedFolderId,
                initialTagIds: preselectedTagIds,
                uncategorizedFolderCreationRequired: resolved.uncategorizedFolderCreationRequired,
                initialMediaMarkType: .audio
            )
        )

        guard editingBookmarkId == nil, !didApplyInitialSharePayload else { return }
        guard case let .audio(audioData, fileExtension) = initialSharePayload else { return }
        didApplyInitialSharePayload = true
        await machine.send(
            .onAudioPicked(
                audioData: audioData,
                fileExtension: fileExtension,
                selectedPath: BookmarkCreationSelectedPathFactory.syntheticMediaSharePath(fileExtension: fileExtension)
            )
        )
    }
}
