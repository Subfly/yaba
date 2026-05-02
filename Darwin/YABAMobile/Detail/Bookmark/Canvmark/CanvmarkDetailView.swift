//
//  CanvmarkDetailView.swift
//  YABA
//

import PhotosUI
import SwiftData
import SwiftUI

/// Canvas bookmark detail — editor host placeholder + chrome (toolbar, overflow, info sheet).
struct CanvmarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = CanvmarkDetailStateMachine()

    @State
    private var reminderDraft = Date().addingTimeInterval(3600)

    @State
    private var showAddLinkSheet = false

    @State
    private var addLinkSheetMode: AddLinkSheetMode = .link

    @State
    private var showAddMentionSheet = false

    @State
    private var galleryPhotoItem: PhotosPickerItem?

    @State
    private var showCameraCapture = false

    init(
        bookmarkId: String,
        onOpenFolder: @escaping (String) -> Void = { _ in },
        onOpenTag: @escaping (String) -> Void = { _ in }
    ) {
        self.bookmarkId = bookmarkId
        self.onOpenFolder = onOpenFolder
        self.onOpenTag = onOpenTag
        var d = FetchDescriptor<YabaBookmark>(
            predicate: #Predicate<YabaBookmark> { $0.bookmarkId == bookmarkId }
        )
        d.fetchLimit = 1
        _bookmarks = Query(d, animation: .smooth)
    }

    var body: some View {
        Group {
            if let bm = bookmark {
                if bm.kind == .canvas {
                    mainContent(for: bm)
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden()
        .task {
            await machine.send(.onInit(bookmarkId: bookmarkId))
        }
        .sheet(isPresented: machine.showDetailSheetBinding) {
            if let bm = bookmark {
                CanvmarkDetailInfoSheet(
                    bookmark: bm,
                    folderAccent: folderColor(for: bm),
                    reminderDate: machine.state.reminderDate,
                    onDeleteReminder: {
                        Task { await machine.send(.onCancelReminder) }
                    },
                    onDeleteAsset: { assetId in
                        Task { await machine.send(.onDeleteCanvasInlineAsset(bookmarkId: bm.bookmarkId, assetId: assetId)) }
                    },
                    onOpenFolder: { folderId in
                        machine.apply { $0.showDetailSheet = false }
                        onOpenFolder(folderId)
                    },
                    onOpenTag: { tagId in
                        machine.apply { $0.showDetailSheet = false }
                        onOpenTag(tagId)
                    }
                )
            }
        }
        .sheet(isPresented: machine.showEditSheetBinding) {
            if let bm = bookmark {
                BookmarkFlowSheet(context: BookmarkFlowContext.edit(bookmarkId: bm.bookmarkId))
            }
        }
        .sheet(isPresented: machine.showMoveSheetBinding) {
            if let bm = bookmark {
                NavigationStack {
                    SelectFolderContent(
                        mode: .bookmarksMove,
                        contextFolderId: bm.folder?.folderId,
                        contextBookmarkIds: [bm.bookmarkId],
                        onPick: { target in
                            if let target {
                                AllBookmarksManager.queueMoveBookmarksToFolder(
                                    bookmarkIds: [bm.bookmarkId],
                                    targetFolderId: target
                                )
                            }
                            machine.apply { $0.showMoveSheet = false }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: machine.showReminderSheetBinding) {
            NavigationStack {
                DatePicker(
                    "Setup Reminder Picker Title",
                    selection: $reminderDraft,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Setup Reminder Title")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { machine.apply { $0.showReminderSheet = false } }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            Task {
                                await machine.send(.onRequestNotificationPermission)
                                await machine.send(
                                    .onScheduleReminder(
                                        titleKey: "Reminder Default Title",
                                        messageKey: "Reminder Default Body",
                                        fireAt: reminderDraft
                                    )
                                )
                            }
                            machine.apply { $0.showReminderSheet = false }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddLinkSheet) {
            NavigationStack {
                AddLinkSheet(mode: addLinkSheetMode) { _, _ in
                    showAddLinkSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddMentionSheet) {
            NavigationStack {
                AddMentionSheet(excludeBookmarkId: bookmarkId) { _, _ in
                    showAddMentionSheet = false
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraCapture) {
            CameraCapturePicker(
                onDismiss: { showCameraCapture = false },
                onCapture: { data in
                    showCameraCapture = false
                    machine.handlePickedInlineImage(data: data, bookmarkId: bookmarkId, storedPathExtension: "jpg")
                }
            )
            .ignoresSafeArea()
        }
        .alert("Delete Bookmark Title", isPresented: machine.showDeleteAlertBinding) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await machine.send(.onDeleteBookmark(bookmarkId: bookmarkId))
                    dismiss()
                }
            }
        } message: {
            if let bm = bookmark {
                Text("Delete Content Message \(bm.label)")
            }
        }
    }

    private var bookmark: YabaBookmark? { bookmarks.first }

    private func folderColor(for bm: YabaBookmark) -> Color {
        bm.folder?.color.getUIColor() ?? .accentColor
    }

    @ViewBuilder
    private func mainContent(for bm: YabaBookmark) -> some View {
        let folderTint = folderColor(for: bm)
        ZStack(alignment: .bottom) {
            Color(.systemBackground)
                .ignoresSafeArea()

            canvasPlaceholder(accent: folderTint)

            HStack {
                Spacer(minLength: 0)
                CanvmarkEditorFloatingToolbar(
                    folderAccent: folderTint,
                    isVisible: true,
                    onTool: { _ in },
                    onRequestAddLinkSheet: { mode in
                        addLinkSheetMode = mode
                        showAddLinkSheet = true
                    },
                    onRequestAddMentionSheet: {
                        showAddMentionSheet = true
                    },
                    onRequestPickImageFromCamera: {
                        showCameraCapture = true
                    },
                    galleryPhotoItem: $galleryPhotoItem,
                    onUndo: {},
                    onRedo: {}
                )
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    homeToolbarIcon("arrow-left-01")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    machine.apply { $0.showDetailSheet = true }
                } label: {
                    homeToolbarIcon("information-circle")
                }
            }
            if #available(iOS 26, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
        .onChange(of: galleryPhotoItem) { _, new in
            Task {
                guard let new else { return }
                let bid = bm.bookmarkId
                guard let data = try? await new.loadTransferable(type: Data.self) else {
                    await MainActor.run { galleryPhotoItem = nil }
                    return
                }
                await MainActor.run {
                    machine.handlePickedInlineImage(data: data, bookmarkId: bid)
                    galleryPhotoItem = nil
                }
            }
        }
    }

    @ViewBuilder
    private func canvasPlaceholder(accent: Color) -> some View {
        VStack(spacing: 16) {
            YabaIconView(bundleKey: "canvas")
                .frame(width: 56, height: 56)
                .foregroundStyle(accent.opacity(0.85))
            Text("Canvmark Detail Canvas Placeholder Title")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
            Button {
                machine.apply { $0.showEditSheet = true }
            } label: {
                overflowMenuItemLabel("Edit", icon: "edit-02")
            }
            .tint(YabaColor.orange.getUIColor())
            Button {
                machine.apply { $0.showMoveSheet = true }
            } label: {
                overflowMenuItemLabel("Move", icon: "arrow-move-up-right")
            }
            .tint(YabaColor.teal.getUIColor())
            Button {
                AllBookmarksManager.queueToggleBookmarkPinned(bookmarkId: bm.bookmarkId)
            } label: {
                overflowMenuItemLabel(
                    bm.isPinned ? "Bookmark Detail Unpin Action" : "Bookmark Detail Pin Action",
                    icon: bm.isPinned ? "pin" : "pin-off"
                )
            }
            .tint(YabaColor.yellow.getUIColor())
            Menu {
                Button {
                    // PNG export — canvas bridge TBD
                } label: {
                    overflowMenuItemLabel("Canvmark Option Export PNG Action Label", icon: "png-02")
                }
                .tint(YabaColor.gray.getUIColor())
                Button {
                    // SVG export — canvas bridge TBD
                } label: {
                    overflowMenuItemLabel("Canvmark Option Export SVG Action Label", icon: "svg-02")
                }
                .tint(YabaColor.yellow.getUIColor())
                Divider()
                Toggle(isOn: exportIncludeBackgroundBinding()) {
                    Text("Canvmark Option Export Background Action Label")
                }
                .menuActionDismissBehavior(.disabled)
                .tint(folderColor(for: bm))
            } label: {
                overflowMenuItemLabel("Canvmark Option Export Action Label", icon: "download-01")
            }
            .tint(YabaColor.blue.getUIColor())
            if machine.state.reminderDate == nil {
                Button {
                    machine.apply { $0.showReminderSheet = true }
                } label: {
                    overflowMenuItemLabel("Remind Me", icon: "notification-01")
                }
                .tint(YabaColor.yellow.getUIColor())
            }
            Divider()
            if machine.state.reminderDate != nil {
                Button {
                    Task { await machine.send(.onCancelReminder) }
                } label: {
                    overflowMenuItemLabel(
                        "Bookmark Detail Cancel Reminder Action",
                        icon: "notification-off-03"
                    )
                }
                .tint(YabaColor.red.getUIColor())
            }
            Button {
                machine.apply { $0.showDeleteAlert = true }
            } label: {
                overflowMenuItemLabel("Delete", icon: "delete-02")
            }
            .tint(YabaColor.red.getUIColor())
        } label: {
            homeToolbarIcon("more-horizontal-circle-02")
        }
    }

    private func exportIncludeBackgroundBinding() -> Binding<Bool> {
        Binding(
            get: { machine.state.exportIncludeBackground },
            set: { newValue in machine.apply { $0.exportIncludeBackground = newValue } }
        )
    }

    @ViewBuilder
    private func homeToolbarIcon(_ bundleKey: String) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .frame(width: 22, height: 22)
    }

    @ViewBuilder
    private func overflowMenuItemLabel(_ key: LocalizedStringKey, icon: String) -> some View {
        Label {
            Text(key)
        } icon: {
            YabaIconView(bundleKey: icon)
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}
