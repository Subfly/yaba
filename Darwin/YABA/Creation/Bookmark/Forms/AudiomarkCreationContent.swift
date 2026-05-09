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

    private func dismissOrCancelBookmarkCreation() {
        if let bookmarkCreationOnCloseRequest {
            bookmarkCreationOnCloseRequest()
        } else {
            dismiss()
        }
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
                await machine.send(.onAudioPicked(audioData: data, fileExtension: normalized))
            }
        }
        .sheet(isPresented: $showRecorderSheet) {
            NavigationStack {
                AudioRecorderSheet(
                    onDismiss: { showRecorderSheet = false },
                    onDone: { data, ext in
                        Task {
                            await machine.send(.onAudioPicked(audioData: data, fileExtension: ext))
                            showRecorderSheet = false
                        }
                    }
                )
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
    }

    private func formList(
        mainTint: Color,
        folderForPresentation: FolderModel?
    ) -> some View {
        List {
            Section {
                previewContent(fallbackIcon: "audio-wave-01", mainTint: mainTint)
                    .bookmarkCreationPreviewListRowBackground(appearance: previewContentAppearance)

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
                previewHeader(mainTint: mainTint)
            }

            Section {
                TextField(
                    "",
                    text: labelBinding,
                    prompt: Text("Create Bookmark Title Placeholder")
                )
                .safeAreaInset(edge: .leading) { fieldIcon("text", mainTint: mainTint) }
                TextField(
                    "",
                    text: descriptionBinding,
                    prompt: Text("Create Bookmark Description Placeholder"),
                    axis: .vertical
                )
                .lineLimit(3 ... 8)
                .safeAreaInset(edge: .leading) { fieldIcon("paragraph", mainTint: mainTint) }
                Toggle(isOn: isPinnedBinding) {
                    Label {
                        Text("Bookmark Creation Toggle Pinned Title")
                    } icon: {
                        fieldIcon(machine.state.isPinned ? "pin" : "pin-off", mainTint: mainTint)
                            .animation(.smooth, value: machine.state.isPinned)
                    }
                }
            } header: {
                Label {
                    Text("Info")
                } icon: {
                    YabaIconView(bundleKey: "information-circle")
                        .frame(width: 22, height: 22)
                }
            }

            BookmarkFormFolderTagRows(
                folderForPresentation: folderForPresentation,
                selectedTagIds: machine.state.selectedTagIds,
                onFolderNavigate: { showFolderSheet = true },
                onTagsNavigate: { showTagSheet = true }
            )

            if let lastError = machine.state.lastError {
                Section {
                    Text(lastError)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .tint(mainTint)
        #if !os(visionOS)
        .scrollDismissesKeyboard(.immediately)
        #endif
        .navigationTitle(
            LocalizedStringKey(isEditing ? "Edit Bookmark Title" : "Create Bookmark Title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismissOrCancelBookmarkCreation()
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

    private func previewHeader(mainTint: Color) -> some View {
        HStack {
            Label {
                Text("Preview")
            } icon: {
                YabaIconView(bundleKey: "audio-wave-01")
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            Spacer()
            Button {
                withAnimation {
                    switch previewContentAppearance {
                    case .list:
                        previewContentAppearance = .cardSmallImage
                    case .cardSmallImage:
                        previewContentAppearance = .cardBigImage
                    case .cardBigImage:
                        previewContentAppearance = .grid
                    case .grid:
                        previewContentAppearance = .list
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if previewContentAppearance == .cardSmallImage || previewContentAppearance == .cardBigImage {
                        Label {
                            Text(ContentAppearance.card.getUITitle())
                                .textCase(.none)
                        } icon: {
                            YabaIconView(bundleKey: ContentAppearance.card.getUIIconName())
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                    }
                    Label {
                        Text(previewContentAppearance.getUITitle())
                            .textCase(.none)
                    } icon: {
                        YabaIconView(bundleKey: previewContentAppearance.getUIIconName())
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(mainTint)
        }
    }

    @ViewBuilder
    private func previewContent(fallbackIcon: String, mainTint: Color) -> some View {
        switch previewContentAppearance {
        case .list:
            HStack(alignment: .center, spacing: 12) {
                previewIcon(fallbackIcon: fallbackIcon, width: 56, height: 56, mainTint: mainTint)
                textPreview(maxDescriptionLines: 2, headlineLimit: 1)
            }
        case .cardSmallImage:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    previewIcon(fallbackIcon: fallbackIcon, width: 56, height: 56, mainTint: mainTint)
                    if machine.state.label.isEmpty {
                        Text("Bookmark Title Placeholder")
                            .font(.headline)
                            .lineLimit(2)
                    } else {
                        Text(machine.state.label)
                            .font(.headline)
                            .lineLimit(2)
                            .animation(.smooth, value: machine.state.label)
                    }
                    Spacer(minLength: 0)
                }
                descriptionPreview(lineLimit: 4)
            }
        case .cardBigImage:
            VStack(alignment: .leading, spacing: 10) {
                previewIcon(fallbackIcon: fallbackIcon, width: nil, height: 180, mainTint: mainTint)
                if machine.state.label.isEmpty {
                    Text("Bookmark Title Placeholder")
                        .font(.headline)
                } else {
                    Text(machine.state.label)
                        .font(.headline)
                        .animation(.smooth, value: machine.state.label)
                }
                descriptionPreview(lineLimit: 3)
            }
        case .grid:
            HStack {
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    previewIcon(fallbackIcon: fallbackIcon, width: 200, height: 200, mainTint: mainTint)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if machine.state.label.isEmpty {
                                Text("Bookmark Title Placeholder")
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(machine.state.label)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .animation(.smooth, value: machine.state.label)
                            }
                            Spacer(minLength: 0)
                        }
                        descriptionPreview(lineLimit: 2)
                    }
                    .padding()
                }
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                }
                .frame(width: 200)
                Spacer(minLength: 0)
            }
        }
    }

    private func textPreview(maxDescriptionLines: Int, headlineLimit: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if machine.state.label.isEmpty {
                Text("Bookmark Title Placeholder")
                    .font(.headline)
                    .lineLimit(headlineLimit)
            } else {
                Text(machine.state.label)
                    .font(.headline)
                    .lineLimit(headlineLimit)
                    .animation(.smooth, value: machine.state.label)
            }
            descriptionPreview(lineLimit: maxDescriptionLines)
        }
    }

    private func descriptionPreview(lineLimit: Int) -> some View {
        Group {
            if machine.state.bookmarkDescription.isEmpty {
                Text("Bookmark Description Placeholder")
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
            } else {
                Text(machine.state.bookmarkDescription)
                    .foregroundStyle(.secondary)
                    .lineLimit(lineLimit)
                    .animation(.smooth, value: machine.state.bookmarkDescription)
            }
        }
    }

    @ViewBuilder
    private func previewIcon(
        fallbackIcon: String,
        width: CGFloat?,
        height: CGFloat,
        mainTint: Color
    ) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(mainTint.opacity(0.25))
            .frame(width: width, height: height)
            .overlay {
                YabaIconView(bundleKey: fallbackIcon)
                    .frame(width: 28, height: 28)
                    .foregroundStyle(mainTint)
            }
    }

    private func fieldIcon(_ bundleKey: String, mainTint: Color) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(mainTint)
    }

    private func syncPreviewAppearanceFromMachine() {
        switch machine.state.bookmarkAppearance {
        case .list:
            previewContentAppearance = .list
        case .card:
            previewContentAppearance = machine.state.cardImageSizing == .big ? .cardBigImage : .cardSmallImage
        case .grid:
            previewContentAppearance = .grid
        }
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
        await machine.send(.onAudioPicked(audioData: audioData, fileExtension: fileExtension))
    }
}

private extension View {
    @ViewBuilder
    func bookmarkCreationActionButtonLabelStyle(mainTint: Color, isDisabled: Bool) -> some View {
        self
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDisabled ? mainTint.opacity(0.45) : mainTint)
            }
            .foregroundStyle(.white)
    }
}
