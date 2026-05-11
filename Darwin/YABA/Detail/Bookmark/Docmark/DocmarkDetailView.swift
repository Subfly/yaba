//
//  DocmarkDetailView.swift
//  YABA
//
//  Document bookmark detail (PDFKit + CSV spreadsheet + Readium EPUB) plus shared chrome / overflow actions.
//

import SwiftData
import SwiftUI

struct DocmarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void
    var showsBackButton: Bool = true

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
        onOpenTag: @escaping (String) -> Void = { _ in },
        showsBackButton: Bool = true
    ) {
        self.bookmarkId = bookmarkId
        self.onOpenFolder = onOpenFolder
        self.onOpenTag = onOpenTag
        self.showsBackButton = showsBackButton
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
                    folderAccent: BookmarkDetailChrome.folderAccent(for: bm),
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
                    BookmarkDetailMoveToFolderPickContent(
                        bookmarkId: bm.bookmarkId,
                        contextFolderId: bm.folder?.folderId,
                        onComplete: { showMoveSheet = false }
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
            BookmarkDetailReminderPickerSheetContent(
                reminderDraft: $reminderDraft,
                onCancel: { showReminderSheet = false },
                onConfirm: {
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
            )
        }
        .bookmarkDetailDeleteBookmarkAlert(
            isPresented: $showDeleteAlert,
            bookmarkLabel: bookmark?.label ?? "",
            onDelete: { await machine.send(.onDeleteBookmark(bookmarkId: bookmarkId)) },
            dismiss: dismiss
        )
    }

    private var bookmark: YabaBookmark? { bookmarks.first }

    @ViewBuilder
    private func mainContent(for bm: YabaBookmark) -> some View {
        let folderTint = BookmarkDetailChrome.folderAccent(for: bm)
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
            case .pdf:
                PDFDocmarkDetailView(
                    pdfData: bm.docDetail?.payload?.bytes ?? Data(),
                    folderTint: folderTint
                )
            case .epub:
                EPUBDocmarkDetailView(
                    epubData: bm.docDetail?.payload?.bytes ?? Data(),
                    folderTint: folderTint,
                    machine: machine
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsBackButton {
                BookmarkDetailPrimaryToolbarPieces.backDismissButton { dismiss() }
            }
            BookmarkDetailPrimaryToolbarPieces.bookmarkInfoSheetGlyphButton { showDetailSheet = true }
            BookmarkDetailPrimaryToolbarPieces.trailingOverflowChrome {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
    }

    private func resolvedDocmarkType(for bm: YabaBookmark) -> DocmarkType {
        bm.docDetail?.docmarkType ?? .pdf
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
            Button {
                showEditSheet = true
            } label: {
                BookmarkDetailOverflowRowLabel(title: "Edit", iconBundleKey: "edit-02")
            }
            .tint(YabaColor.orange.getUIColor())
            Button {
                showMoveSheet = true
            } label: {
                BookmarkDetailOverflowRowLabel(title: "Move", iconBundleKey: "arrow-move-up-right")
            }
            .tint(YabaColor.teal.getUIColor())
            Button {
                AllBookmarksManager.queueToggleBookmarkPinned(bookmarkId: bm.bookmarkId)
            } label: {
                BookmarkDetailOverflowRowLabel(
                    title: bm.isPinned ? "Bookmark Detail Unpin Action" : "Bookmark Detail Pin Action",
                    iconBundleKey: bm.isPinned ? "pin" : "pin-off"
                )
            }
            .tint(YabaColor.yellow.getUIColor())
            Button {
                machine.prepareDocumentSaveCopy(bookmarkLabel: bm.label)
            } label: {
                BookmarkDetailOverflowRowLabel(
                    title: LocalizedStringKey("Bookmark Detail Save Copy Label"),
                    iconBundleKey: "download-01"
                )
            }
            .tint(YabaColor.blue.getUIColor())
            if machine.state.reminderDate == nil {
                Button {
                    showReminderSheet = true
                } label: {
                    BookmarkDetailOverflowRowLabel(title: "Remind Me", iconBundleKey: "notification-01")
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
                BookmarkDetailOverflowRowLabel(title: "Share", iconBundleKey: "share-03")
            }
            .tint(YabaColor.indigo.getUIColor())
            Divider()
            if machine.state.reminderDate != nil {
                Button {
                    Task { await machine.send(.onCancelReminder) }
                } label: {
                    BookmarkDetailOverflowRowLabel(
                        title: "Bookmark Detail Cancel Reminder Action",
                        iconBundleKey: "notification-off-03"
                    )
                }
                .tint(YabaColor.red.getUIColor())
            }
            Button {
                showDeleteAlert = true
            } label: {
                BookmarkDetailOverflowRowLabel(title: "Delete", iconBundleKey: "delete-02")
            }
            .tint(YabaColor.red.getUIColor())
        } label: {
            BookmarkDetailHomeToolbarGlyph(bundleKey: "more-horizontal-circle-02")
        }
    }
}
