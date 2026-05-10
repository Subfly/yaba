//
//  Created by Ali Taha on 20.04.2026.
//

import SwiftData
import SwiftUI

struct LinkmarkDetailInfoSheet: View {
    @Environment(\.openURL)
    private var openURL

    let bookmark: YabaBookmark
    let folderAccent: Color
    let reminderDate: Date?
    let onDeleteReminder: () -> Void
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let imageData = bookmark.imageDataHolder,
                       let image = UIImage(data: imageData)
                    {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                if let urlString = bookmark.linkDetail?.url,
                                   let url = URL(string: urlString)
                                {
                                    openURL(url)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                    } else {
                        emptyCardContent(icon: "image-not-found-01", title: "Bookmark Detail Image Error Title")
                            .listRowBackground(Color.clear)
                    }
                } header: {
                    BookmarkDetailInfoSectionHeaderBar(
                        folderAccent: folderAccent,
                        title: "Bookmark Detail Image Header Title",
                        iconBundleKey: "image-03"
                    )
                } footer: {
                    if let url = bookmark.linkDetail?.url, !url.isEmpty {
                        HStack(alignment: .center, spacing: 10) {
                            YabaIconView(bundleKey: "link-02")
                                .frame(width: 18, height: 18)
                                .foregroundStyle(folderAccent)
                            Text(url)
                                .lineLimit(2)
                        }
                    }
                }

                BookmarkDetailBookmarkInfoCoreSection(
                    folderAccent: folderAccent,
                    label: bookmark.label,
                    bookmarkDescription: bookmark.bookmarkDescription,
                    createdAt: bookmark.createdAt,
                    editedAt: bookmark.editedAt,
                    reminderDate: reminderDate,
                    onDeleteReminderSwipe: onDeleteReminder
                )

                Section {
                    BookmarkDetailInfoCaptionValueRow(
                        folderAccent: folderAccent,
                        captionKey: "Bookmark Detail URL Label",
                        iconBundleKey: "link-02",
                        value: bookmark.linkDetail?.url
                    )
                    BookmarkDetailInfoCaptionValueRow(
                        folderAccent: folderAccent,
                        captionKey: "Bookmark Detail Metadata Title Label",
                        iconBundleKey: "text",
                        value: bookmark.linkDetail?.metadataTitle
                    )
                    BookmarkDetailInfoCaptionValueRow(
                        folderAccent: folderAccent,
                        captionKey: "Bookmark Creation Metadata Description Label",
                        iconBundleKey: "paragraph",
                        value: bookmark.linkDetail?.metadataDescription
                    )
                } header: {
                    BookmarkDetailInfoSectionHeaderBar(
                        folderAccent: folderAccent,
                        title: "Bookmark Creation Metadata Section Title",
                        iconBundleKey: "database-01"
                    )
                }

                bookmark.bookmarkDetailInfoFolderSection(onOpenFolder: onOpenFolder)
                bookmark.bookmarkDetailInfoTagsSection(onOpenTag: onOpenTag)
            }
            .bookmarkDetailInfoSheetListChrome(folderAccent: folderAccent)
        }
    }

    private func emptyCardContent(icon: String, title: LocalizedStringKey) -> some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                YabaIconView(bundleKey: icon)
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(folderAccent)
            }
        } description: {
            EmptyView()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial.opacity(0.5))
        )
    }
}
