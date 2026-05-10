//
//  DocmarkDetailInfoSheet.swift
//  YABA
//

import SwiftData
import SwiftUI

struct DocmarkDetailInfoSheet: View {
    let bookmark: YabaBookmark
    let folderAccent: Color
    let reminderDate: Date?
    let onDeleteReminder: () -> Void
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                BookmarkDetailBookmarkInfoCoreSection(
                    folderAccent: folderAccent,
                    label: bookmark.label,
                    bookmarkDescription: bookmark.bookmarkDescription,
                    createdAt: bookmark.createdAt,
                    editedAt: bookmark.editedAt,
                    reminderDate: reminderDate,
                    onDeleteReminderSwipe: onDeleteReminder
                )

                bookmark.bookmarkDetailInfoFolderSection(onOpenFolder: onOpenFolder)
                bookmark.bookmarkDetailInfoTagsSection(onOpenTag: onOpenTag)
            }
            .bookmarkDetailInfoSheetListChrome(folderAccent: folderAccent)
        }
    }
}
