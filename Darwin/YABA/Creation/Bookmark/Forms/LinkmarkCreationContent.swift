//
//  LinkmarkCreationContent.swift
//  YABA
//
//  Created by Ali Taha on 16.04.2026.
//

import SwiftData
import SwiftUI

struct LinkmarkCreationContent: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.bookmarkCreationOnCloseRequest)
    private var bookmarkCreationOnCloseRequest

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var machine = LinkmarkCreationStateMachine()

    @State
    private var showFolderSheet = false

    @State
    private var showTagSheet = false

    @State
    private var previewContentAppearance: PreviewContentAppearance = .list

    let preselectedFolderId: String?
    let preselectedTagIds: [String]
    let initialUrl: String?
    let editingBookmarkId: String?
    let locksImportedPrimaryPayload: Bool
    let onDone: () -> Void

    init(
        preselectedFolderId: String?,
        preselectedTagIds: [String],
        initialUrl: String?,
        editingBookmarkId: String?,
        locksImportedPrimaryPayload: Bool = false,
        onDone: @escaping () -> Void
    ) {
        self.preselectedFolderId = preselectedFolderId
        self.preselectedTagIds = preselectedTagIds
        self.initialUrl = initialUrl
        self.editingBookmarkId = editingBookmarkId
        self.locksImportedPrimaryPayload = locksImportedPrimaryPayload
        self.onDone = onDone
        _machine = State(initialValue: LinkmarkCreationStateMachine())
        _showFolderSheet = State(initialValue: false)
        _showTagSheet = State(initialValue: false)
        _previewContentAppearance = State(initialValue: .list)
    }

    /// Drives `bootstrap` when edit target or prefilled URL from share/host changes; `editingBookmarkId` alone misses late `initialUrl` updates.
    private var linkmarkBootstrapIdentity: String {
        "\(editingBookmarkId ?? "")\u{1e}\(initialUrl ?? "")"
    }

    private var isEditing: Bool {
        editingBookmarkId != nil
    }

    private var restrictsPrimaryPayloadUI: Bool {
        isEditing || locksImportedPrimaryPayload
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
        .task(id: linkmarkBootstrapIdentity) {
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
                    imageData: machine.state.previewImageData,
                    fallbackIcon: "link-02",
                    mainTint: mainTint,
                    label: machine.state.label,
                    bookmarkDescription: machine.state.bookmarkDescription,
                    bigCardImageHeight: 160
                )
                .bookmarkCreationPreviewListRowBackground(appearance: previewContentAppearance)
                .redacted(reason: machine.state.isFetchingLinkContent ? .placeholder : [])
            } header: {
                BookmarkCreationPreviewHeader(
                    previewContentAppearance: $previewContentAppearance,
                    mainTint: mainTint
                )
            }

            Section {
                TextField(
                    "",
                    text: urlBinding,
                    prompt: Text("Create Bookmark URL Placeholder")
                )
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disabled(restrictsPrimaryPayloadUI)
                .safeAreaInset(edge: .leading) {
                    BookmarkCreationLeadingFieldIcon(bundleKey: "link-02", mainTint: mainTint)
                }

                if !restrictsPrimaryPayloadUI {
                    if let cleaned = machine.state.cleanedUrl, !cleaned.isEmpty {
                        HStack {
                            BookmarkCreationLeadingFieldIcon(bundleKey: "clean", mainTint: mainTint)
                            Text(cleaned)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            BookmarkCreationLeadingFieldIcon(bundleKey: "clean", mainTint: mainTint)
                            Text("Create Bookmark Cleaned URL Placeholder")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            } header: {
                Label {
                    Text("Link")
                } icon: {
                    YabaIconView(bundleKey: "link-04")
                        .frame(width: 22, height: 22)
                }
            } footer: {
                if !restrictsPrimaryPayloadUI {
                    Text("Bookmark Creation Link Info Message")
                }
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
                BookmarkCreationInfoSectionHeaderBuilders.infoHeaderAccessory {
                    if !isEditing && hasApplicableMetadata {
                        Button {
                            Task { await machine.send(.onApplyFromMetadata) }
                        } label: {
                            Text("Bookmark Creation Apply From Metadata Title")
                                .textCase(.none)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(mainTint)
                    }
                }
            }

            if hasMetadataRows {
                Section {
                    metadataRow("Bookmark Creation Metadata Title Label", icon: "text", value: machine.state.metadataTitle, mainTint: mainTint)
                    metadataRow("Bookmark Creation Metadata Description Label", icon: "paragraph", value: machine.state.metadataDescription, mainTint: mainTint)
                    metadataRow("Bookmark Creation Metadata Author Label", icon: "user-edit-01", value: machine.state.metadataAuthor, mainTint: mainTint)
                    metadataRow("Bookmark Creation Metadata Date Label", icon: "calendar-03", value: machine.state.metadataDate, mainTint: mainTint)
                    metadataRow("Bookmark Creation Metadata Video URL Label", icon: "computer-video", value: machine.state.videoUrl, mainTint: mainTint)
                    metadataRow("Bookmark Creation Metadata Audio URL Label", icon: "audio-wave-01", value: machine.state.audioUrl, mainTint: mainTint)
                } header: {
                    Label {
                        Text("Bookmark Creation Metadata Section Title")
                    } icon: {
                        YabaIconView(bundleKey: "database-01")
                            .frame(width: 22, height: 22)
                    }
                }
            }

            BookmarkFormFolderTagRows(
                folderForPresentation: folderForPresentation,
                selectedTagIds: machine.state.selectedTagIds,
                onFolderNavigate: { showFolderSheet = true },
                onTagsNavigate: { showTagSheet = true }
            )
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
                        if machine.state.lastError == nil {
                            onDone()
                        }
                    }
                } label: {
                    Text("Done")
                }
                .disabled(machine.state.isSaving || machine.state.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var hasApplicableMetadata: Bool {
        let title = machine.state.metadataTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let description = machine.state.metadataDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !title.isEmpty || !description.isEmpty
    }

    private var hasMetadataRows: Bool {
        [
            machine.state.metadataTitle,
            machine.state.metadataDescription,
            machine.state.metadataAuthor,
            machine.state.metadataDate,
            machine.state.videoUrl,
            machine.state.audioUrl
        ]
        .contains { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var urlBinding: Binding<String> {
        Binding(
            get: { machine.state.url },
            set: { newValue in
                Task {
                    await machine.send(.onChangeUrl(newValue))
                }
            }
        )
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

    @ViewBuilder
    private func metadataRow(
        _ key: LocalizedStringKey,
        icon: String,
        value: String?,
        mainTint: Color
    ) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .top, spacing: 12) {
                BookmarkCreationLeadingFieldIcon(bundleKey: icon, mainTint: mainTint)
                    .frame(width: 24, height: 24)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                }
            }
        }
    }

    private func bootstrap() async {
        if let bid = editingBookmarkId,
           let bookmark = BookmarkFlowHydration.fetchBookmark(bookmarkId: bid, modelContext: modelContext)
        {
            machine.replaceState(BookmarkFlowHydration.linkmarkUIState(from: bookmark))
            return
        }
        let resolved = BookmarkCreationFolderResolution.resolveForNewBookmark(
            modelContext: modelContext,
            preselectedFolderId: preselectedFolderId
        )
        await machine.send(
            .onInit(
                linkmarkId: nil,
                initialUrl: initialUrl,
                initialFolderId: resolved.selectedFolderId,
                initialTagIds: preselectedTagIds,
                uncategorizedFolderCreationRequired: resolved.uncategorizedFolderCreationRequired
            )
        )
    }
}
