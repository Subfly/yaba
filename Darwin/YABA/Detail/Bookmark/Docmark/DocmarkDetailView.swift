//
//  DocmarkDetailView.swift
//  YABA
//
//  Document bookmark detail (PDFKit + CSV spreadsheet preview) plus shared chrome / overflow actions.
//

import SwiftData
import SwiftUI

struct DocmarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = DocmarkDetailStateMachine()

    @State
    private var showDetailSheet = false

    @State
    private var showEditSheet = false

    @State
    private var showMoveSheet = false

    @State
    private var showShareSheet = false

    @State
    private var shareURL: URL?

    @State
    private var showDeleteAlert = false

    @State
    private var showReminderSheet = false

    @State
    private var reminderDraft = Date().addingTimeInterval(3600)

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
                if bm.kind == .file {
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
        .sheet(isPresented: $showDetailSheet) {
            if let bm = bookmark {
                DocmarkDetailInfoSheet(
                    bookmark: bm,
                    folderAccent: folderColor(for: bm),
                    reminderDate: machine.state.reminderDate,
                    onDeleteReminder: {
                        Task { await machine.send(.onCancelReminder) }
                    },
                    onOpenFolder: { folderId in
                        showDetailSheet = false
                        onOpenFolder(folderId)
                    },
                    onOpenTag: { tagId in
                        showDetailSheet = false
                        onOpenTag(tagId)
                    }
                )
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let bm = bookmark {
                BookmarkFlowSheet(context: BookmarkFlowContext.edit(bookmarkId: bm.bookmarkId))
            }
        }
        .sheet(isPresented: $showMoveSheet) {
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
                            showMoveSheet = false
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            shareURL = nil
            Task { await machine.send(.onConsumePendingShare) }
        }) {
            if let url = shareURL {
                ActivityItemsShareSheet(items: [url])
            }
        }
        .sheet(isPresented: machine.showDocumentSaveCopyPickerBinding) {
            ExportDirectoryPicker { url in
                Task { @MainActor in
                    machine.finalizeDocumentSaveCopyDirectory(url)
                }
            }
        }
        .sheet(isPresented: $showReminderSheet) {
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
                        Button("Cancel") { showReminderSheet = false }
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
                            showReminderSheet = false
                        }
                    }
                }
            }
        }
        .alert("Delete Bookmark Title", isPresented: $showDeleteAlert) {
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

    @ViewBuilder
    private func mainContent(for bm: YabaBookmark) -> some View {
        let folderTint = folderColor(for: bm)
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            switch resolvedDocmarkType(for: bm) {
            case .csv:
                CSVDocmarkDetailView(
                    bookmarkId: bm.bookmarkId,
                    csvBytes: bm.docDetail?.payload?.bytes ?? Data(),
                    folderTint: folderTint
                )
            case .pdf, .epub:
                PDFDocmarkDetailView(
                    pdfData: bm.docDetail?.payload?.bytes ?? Data(),
                    folderTint: folderTint
                )
            }
        }
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
                    showDetailSheet = true
                } label: {
                    homeToolbarIcon("information-circle")
                }
            }
            if #available(iOS 26, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }
            ToolbarItem(placement: .topBarTrailing) {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
    }

    private func folderColor(for bm: YabaBookmark) -> Color {
        bm.folder?.color.getUIColor() ?? .accentColor
    }

    private func resolvedDocmarkType(for bm: YabaBookmark) -> DocmarkType {
        DocmarkType(rawValue: bm.docDetail?.docmarkTypeRaw ?? "") ?? .pdf
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
            Button {
                showEditSheet = true
            } label: {
                overflowMenuItemLabel("Edit", icon: "edit-02")
            }
            .tint(YabaColor.orange.getUIColor())
            Button {
                showMoveSheet = true
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
            Button {
                machine.prepareDocumentSaveCopy(bookmarkLabel: bm.label)
            } label: {
                overflowMenuItemLabel(LocalizedStringKey("Bookmark Detail Save Copy Label"), icon: "download-01")
            }
            .tint(YabaColor.blue.getUIColor())
            if machine.state.reminderDate == nil {
                Button {
                    showReminderSheet = true
                } label: {
                    overflowMenuItemLabel("Remind Me", icon: "notification-01")
                }
                .tint(YabaColor.yellow.getUIColor())
            }
            Button {
                Task {
                    await machine.send(.onShareDocument)
                    if let url = machine.state.pendingShareFileURL {
                        shareURL = url
                        showShareSheet = true
                    }
                }
            } label: {
                overflowMenuItemLabel("Share", icon: "share-03")
            }
            .tint(YabaColor.indigo.getUIColor())
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
                showDeleteAlert = true
            } label: {
                overflowMenuItemLabel("Delete", icon: "delete-02")
            }
            .tint(YabaColor.red.getUIColor())
        } label: {
            homeToolbarIcon("more-horizontal-circle-02")
        }
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
