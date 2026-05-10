//
//  CSVDocmarkCreationContent.swift
//  YABA
//
//  CSV document bookmark creation (no file metadata extraction).
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVDocmarkCreationContent: View {
    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.bookmarkCreationOnCloseRequest)
    private var bookmarkCreationOnCloseRequest

    let machine: DocmarkCreationStateMachine
    let mainTint: Color
    let folderForPresentation: FolderModel?
    @Binding
    var showFolderSheet: Bool
    @Binding
    var showTagSheet: Bool
    let editingBookmarkId: String?
    let locksImportedPrimaryPayload: Bool
    let onDone: () -> Void

    @State
    private var showFileImporter = false

    @State
    private var previewContentAppearance: PreviewContentAppearance = .list

    private var isEditing: Bool {
        editingBookmarkId != nil
    }

    private var restrictsPrimaryPayloadUI: Bool {
        isEditing || locksImportedPrimaryPayload
    }

    var body: some View {
        formList(mainTint: mainTint, folderForPresentation: folderForPresentation)
            .task(id: editingBookmarkId) {
                syncPreviewAppearanceFromMachine()
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    guard let url = try? result.get().first else { return }
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer {
                        if scoped { url.stopAccessingSecurityScopedResource() }
                    }
                    guard url.pathExtension.lowercased() == "csv" else { return }
                    guard let data = try? Data(contentsOf: url) else { return }
                    await machine.send(
                        .onDocumentFromShare(
                            data,
                            sourceFileName: url.lastPathComponent,
                            selectedPath: url.path,
                            docmarkType: .csv
                        )
                    )
                }
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
                    fallbackIcon: "csv-02",
                    mainTint: mainTint,
                    label: machine.state.label,
                    bookmarkDescription: machine.state.bookmarkDescription
                )
                .bookmarkCreationPreviewListRowBackground(appearance: previewContentAppearance)
                .redacted(reason: machine.state.isLoading ? .placeholder : [])

                if let path = machine.state.selectedFilePath, !path.isEmpty {
                    BookmarkCreationSelectedContentIndicator(path: path, mainTint: mainTint)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Button {
                    Task { await machine.send(.onPickDocument) }
                    showFileImporter = true
                } label: {
                    Label {
                        Text("Bookmark Creation Pick CSV Document Action")
                    } icon: {
                        YabaIconView(bundleKey: "add-circle")
                            .frame(width: 24, height: 24)
                    }
                    .bookmarkCreationActionButtonLabelStyle(
                        mainTint: mainTint,
                        isDisabled: restrictsPrimaryPayloadUI
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .disabled(restrictsPrimaryPayloadUI)
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
                .disabled(!machine.state.canSave || machine.state.isSaving)
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
}
