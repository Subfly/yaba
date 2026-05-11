//
//  BookmarkDetailInfoSheetShared.swift
//  YABA
//

import SwiftUI

// MARK: - Rows

struct BookmarkDetailInfoTextRow: View {
    let folderAccent: Color
    let iconBundleKey: String
    let value: String?
    var emptyPlaceholder: LocalizedStringKey?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            YabaIconView(bundleKey: iconBundleKey)
                .frame(width: 22, height: 22)
                .foregroundStyle(folderAccent)
                .padding(.top, 1)

            if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                Text(value)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            } else if let emptyPlaceholder {
                Text(emptyPlaceholder)
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct BookmarkDetailInfoMetadataRow: View {
    let folderAccent: Color
    let iconBundleKey: String
    let title: LocalizedStringKey
    let value: String
    /// When set, the row exposes trailing swipe-delete for reminders.
    var onDeleteReminderSwipe: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                YabaIconView(bundleKey: iconBundleKey)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(folderAccent)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.footnote.weight(.semibold))
        }
        .modifier(ReminderSwipeActionsModifier(onDelete: onDeleteReminderSwipe))
    }

    private struct ReminderSwipeActionsModifier: ViewModifier {
        let onDelete: (() -> Void)?

        func body(content: Content) -> some View {
            if let onDelete {
                content
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            VStack(spacing: 2) {
                                YabaIconView(bundleKey: "delete-02")
                                    .frame(width: 22, height: 22)
                                Text("Delete")
                                    .font(.caption2)
                            }
                        }
                        .tint(.red)
                    }
            } else {
                content
            }
        }
    }
}

struct BookmarkDetailInfoSectionHeaderBar: View {
    let folderAccent: Color
    let title: LocalizedStringKey
    let iconBundleKey: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            YabaIconView(bundleKey: iconBundleKey)
                .frame(width: 20, height: 20)
                .foregroundStyle(folderAccent)
        }
    }
}

/// Shared “label / description / dates / reminder” block used by bookmark detail info sheets.
struct BookmarkDetailBookmarkInfoCoreSection: View {
    let folderAccent: Color
    let label: String
    let bookmarkDescription: String?
    let createdAt: Date
    let editedAt: Date
    let reminderDate: Date?
    let onDeleteReminderSwipe: () -> Void

    var body: some View {
        Section {
            BookmarkDetailInfoTextRow(
                folderAccent: folderAccent,
                iconBundleKey: "text",
                value: label
            )
            BookmarkDetailInfoTextRow(
                folderAccent: folderAccent,
                iconBundleKey: "paragraph",
                value: bookmarkDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                emptyPlaceholder: "Bookmark Detail No Description Provided"
            )
            BookmarkDetailInfoMetadataRow(
                folderAccent: folderAccent,
                iconBundleKey: "clock-01",
                title: "Bookmark Detail Created At Title",
                value: createdAt.formatted(date: .abbreviated, time: .shortened)
            )
            if createdAt != editedAt {
                BookmarkDetailInfoMetadataRow(
                    folderAccent: folderAccent,
                    iconBundleKey: "edit-02",
                    title: "Bookmark Detail Edited At Title",
                    value: editedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }
            if let reminderDate {
                BookmarkDetailInfoMetadataRow(
                    folderAccent: folderAccent,
                    iconBundleKey: "notification-01",
                    title: "Bookmark Detail Remind Me Title",
                    value: reminderDate.formatted(date: .abbreviated, time: .shortened),
                    onDeleteReminderSwipe: onDeleteReminderSwipe
                )
            }
        } header: {
            BookmarkDetailInfoSectionHeaderBar(
                folderAccent: folderAccent,
                title: "Info",
                iconBundleKey: "information-circle"
            )
        }
    }
}

// MARK: - Folder / Tags

extension YabaBookmark {
    @MainActor
    @ViewBuilder
    func bookmarkDetailInfoFolderSection(onOpenFolder: @escaping (String) -> Void) -> some View {
        if let folder {
            Section {
                PresentableFolderItemView(
                    model: folder,
                    nullModelPresentableColor: .blue,
                    onPressed: {
                        onOpenFolder(folder.folderId)
                    }
                )
            } header: {
                BookmarkDetailInfoSectionHeaderBar(
                    folderAccent: BookmarkDetailChrome.folderAccent(for: self),
                    title: "Folder",
                    iconBundleKey: "folder-01"
                )
            }
        }
    }

    @MainActor
    @ViewBuilder
    func bookmarkDetailInfoTagsSection(onOpenTag: @escaping (String) -> Void) -> some View {
        let accent = BookmarkDetailChrome.folderAccent(for: self)
        Section {
            if tags.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("Bookmark Detail No Tags Added Title")
                    } icon: {
                        YabaIconView(bundleKey: "tags")
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundStyle(accent)
                    }
                } description: {
                    Text("Bookmark Detail No Tags Added Description")
                }
            } else {
                ForEach(tags) { tag in
                    PresentableTagItemView(
                        model: tag,
                        nullModelPresentableColor: .blue,
                        onPressed: {
                            onOpenTag(tag.tagId)
                        },
                        onNavigateToEdit: {}
                    )
                }
            }
        } header: {
            BookmarkDetailInfoSectionHeaderBar(
                folderAccent: accent,
                title: LocalizedStringKey("Tags Title"),
                iconBundleKey: "tag-01"
            )
        }
    }
}

// MARK: - List chrome + Done toolbar

extension View {
    func bookmarkDetailInfoSheetListChrome(folderAccent: Color) -> some View {
        modifier(BookmarkDetailInfoSheetChromeModifier(folderAccent: folderAccent))
    }
}

private struct BookmarkDetailInfoSheetChromeModifier: ViewModifier {
    let folderAccent: Color
    @Environment(\.dismiss)
    private var dismiss

    func body(content: Content) -> some View {
        content
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tint(folderAccent)
            .navigationTitle("Bookmark Detail Sheet Navigation Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
    }
}

/// Link detail metadata rows (caption + body font).
struct BookmarkDetailInfoCaptionValueRow: View {
    let folderAccent: Color
    let captionKey: LocalizedStringKey
    let iconBundleKey: String
    let value: String?

    var body: some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .top, spacing: 12) {
                YabaIconView(bundleKey: iconBundleKey)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(folderAccent)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(captionKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body)
                }
            }
        }
    }
}

extension View {
    func bookmarkDetailInfoListSurfaceOnly() -> some View {
        modifier(BookmarkDetailInfoListSurfaceOnlyModifier())
    }
}

private struct BookmarkDetailInfoListSurfaceOnlyModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if !targetEnvironment(macCatalyst)
        content
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        #else
        content
            .scrollContentBackground(.hidden)
        #endif
    }
}
