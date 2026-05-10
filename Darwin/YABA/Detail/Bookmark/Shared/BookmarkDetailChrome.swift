//
//  BookmarkDetailChrome.swift
//  YABA
//

import SwiftUI

enum BookmarkDetailChrome {
    static func folderAccent(for bookmark: YabaBookmark) -> Color {
        bookmark.folder?.color.getUIColor() ?? .accentColor
    }
}

struct BookmarkDetailHomeToolbarGlyph: View {
    let bundleKey: String

    var body: some View {
        YabaIconView(bundleKey: bundleKey)
            .frame(width: 22, height: 22)
    }
}

struct BookmarkDetailOverflowRowLabel: View {
    let title: LocalizedStringKey
    let iconBundleKey: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            YabaIconView(bundleKey: iconBundleKey)
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}

struct BookmarkDetailReminderPickerSheetContent: View {
    @Binding
    var reminderDraft: Date
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
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
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onConfirm)
                }
            }
        }
    }
}

struct BookmarkDetailMoveToFolderPickContent: View {
    let bookmarkId: String
    let contextFolderId: String?
    let onComplete: () -> Void

    var body: some View {
        SelectFolderContent(
            mode: .bookmarksMove,
            contextFolderId: contextFolderId,
            contextBookmarkIds: [bookmarkId],
            onPick: { target in
                if let target {
                    AllBookmarksManager.queueMoveBookmarksToFolder(
                        bookmarkIds: [bookmarkId],
                        targetFolderId: target
                    )
                }
                onComplete()
            }
        )
    }
}

extension View {
    /// Shared delete confirmation for bookmark detail screens.
    func bookmarkDetailDeleteBookmarkAlert(
        isPresented: Binding<Bool>,
        bookmarkLabel: String,
        onDelete: @escaping () async -> Void,
        dismiss: DismissAction
    ) -> some View {
        alert("Delete Bookmark Title", isPresented: isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await onDelete()
                    dismiss()
                }
            }
        } message: {
            Text("Delete Content Message \(bookmarkLabel)")
        }
    }
}

enum BookmarkDetailPrimaryToolbarPieces {
    @ToolbarContentBuilder
    static func backDismissButton(onTap: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: onTap) {
                BookmarkDetailHomeToolbarGlyph(bundleKey: "arrow-left-01")
            }
        }
    }

    @ToolbarContentBuilder
    static func bookmarkInfoSheetGlyphButton(onTap: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: onTap) {
                BookmarkDetailHomeToolbarGlyph(bundleKey: "information-circle")
            }
        }
    }

    @ToolbarContentBuilder
    static func fixedTrailingToolbarSpacer() -> some ToolbarContent {
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
    }

    @ToolbarContentBuilder
    static func trailingOverflowChrome<M: View>(@ViewBuilder menu: () -> M) -> some ToolbarContent {
        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
            menu()
        }
    }
}

