//
//  MediamarkDetailView.swift
//  YABA
//
//  Media bookmark detail: routes image / video / audio subviews; shared chrome and overflow actions.
//

import SwiftData
import SwiftUI

struct MediamarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = MediamarkDetailStateMachine()

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
                if bm.kind == .media {
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
                MediamarkDetailInfoSheet(
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
        Group {
            switch bm.mediaDetail?.mediaMarkType ?? .image {
            case .image:
                ImagemarkDetailView(bookmark: bm, folderTint: folderTint)
            case .video:
                VideomarkDetailView(bookmark: bm, folderTint: folderTint)
            case .audio:
                AudiomarkDetailView(bookmark: bm, folderTint: folderTint)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            BookmarkDetailPrimaryToolbarPieces.backDismissButton { dismiss() }
            BookmarkDetailPrimaryToolbarPieces.bookmarkInfoSheetGlyphButton { showDetailSheet = true }
            BookmarkDetailPrimaryToolbarPieces.trailingOverflowChrome {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
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
                    iconBundleKey: bm.isPinned ? "pin-off" : "pin"
                )
            }
            .tint(YabaColor.yellow.getUIColor())
            Button {
                Task {
                    if bm.mediaDetail?.mediaMarkType == .audio {
                        await machine.send(.onShareMedia)
                        if let url = machine.state.pendingShareFileURL {
                            shareURL = url
                            showShareSheet = true
                        }
                    } else {
                        await machine.send(.onExportMedia)
                    }
                }
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
                    await machine.send(.onShareMedia)
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
