//
//  MediamarkDetailInfoSheet.swift
//  YABA
//
//  Single info section (no segmented tabs): mirrors Compose imagemark detail layout.
//

import SwiftData
import SwiftUI

struct MediamarkDetailInfoSheet: View {
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
