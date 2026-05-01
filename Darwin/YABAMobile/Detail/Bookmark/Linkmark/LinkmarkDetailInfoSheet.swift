//
//  Created by Ali Taha on 20.04.2026.
//

import SwiftData
import SwiftUI
import UIKit

enum LinkmarkDetailSheetTab: String, CaseIterable, Identifiable, Hashable {
    case info
    case contents

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .info: return "information-circle"
        case .contents: return "align-box-middle-center"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .info: return "Bookmark Detail Sheet Tab Info Title"
        case .contents: return "Bookmark Detail Sheet Tab Contents Title"
        }
    }
}

private struct LinkmarkTocFlatRow: Identifiable {
    let item: LinkmarkMarkdownTocItem
    let depth: Int

    var id: String { item.id }
}

/// Pre-order flatten without recursion (stack machine).
private func flattenLinkmarkTocItems(_ roots: [LinkmarkMarkdownTocItem]) -> [LinkmarkTocFlatRow] {
    var result: [LinkmarkTocFlatRow] = []
    struct Frame {
        var items: [LinkmarkMarkdownTocItem]
        var depth: Int
        var index: Int
    }
    var stack: [Frame] = [Frame(items: roots, depth: 0, index: 0)]

    while !stack.isEmpty {
        let fi = stack.count - 1
        if stack[fi].index >= stack[fi].items.count {
            stack.removeLast()
            continue
        }
        let item = stack[fi].items[stack[fi].index]
        stack[fi].index += 1
        let depth = stack[fi].depth
        result.append(LinkmarkTocFlatRow(item: item, depth: depth))
        if !item.children.isEmpty {
            stack.append(Frame(items: item.children, depth: depth + 1, index: 0))
        }
    }

    return result
}

struct LinkmarkDetailInfoSheet: View {
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.openURL)
    private var openURL

    let bookmark: YabaBookmark
    let tocItems: [LinkmarkMarkdownTocItem]
    let folderAccent: Color
    let reminderDate: Date?
    let onDeleteReminder: () -> Void
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void
    @Binding var selectedTab: LinkmarkDetailSheetTab
    let onTocItemTap: (LinkmarkMarkdownTocItem) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    ForEach(LinkmarkDetailSheetTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
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

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .info:
            linkInfoScroll
        case .contents:
            tocList
        }
    }

    private var linkInfoScroll: some View {
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
                sectionHeader("Bookmark Detail Image Header Title", icon: "image-03")
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

            Section {
                infoTextRow(icon: "text", value: bookmark.label)
                infoTextRow(
                    icon: "paragraph",
                    value: bookmark.bookmarkDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
                    emptyPlaceholder: "Bookmark Detail No Description Provided"
                )
                infoMetadataRow(
                    icon: "clock-01",
                    title: "Bookmark Detail Created At Title",
                    value: bookmark.createdAt.formatted(date: .abbreviated, time: .shortened)
                )
                if bookmark.createdAt != bookmark.editedAt {
                    infoMetadataRow(
                        icon: "edit-02",
                        title: "Bookmark Detail Edited At Title",
                        value: bookmark.editedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
                if let reminderDate {
                    infoMetadataRow(
                        icon: "notification-01",
                        title: "Bookmark Detail Remind Me Title",
                        value: reminderDate.formatted(date: .abbreviated, time: .shortened)
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDeleteReminder()
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
                }
            } header: {
                sectionHeader("Info", icon: "information-circle")
            }

            Section {
                metadataRow("Bookmark Detail URL Label", icon: "link-02", value: bookmark.linkDetail?.url)
                metadataRow("Bookmark Detail Metadata Title Label", icon: "text", value: bookmark.linkDetail?.metadataTitle)
                metadataRow("Bookmark Creation Metadata Description Label", icon: "paragraph", value: bookmark.linkDetail?.metadataDescription)
            } header: {
                sectionHeader("Bookmark Creation Metadata Section Title", icon: "database-01")
            }

            if let folder = bookmark.folder {
                Section {
                    PresentableFolderItemView(
                        model: folder,
                        nullModelPresentableColor: .blue,
                        onPressed: {
                            onOpenFolder(folder.folderId)
                        }
                    )
                } header: {
                    sectionHeader("Folder", icon: "folder-01")
                }
            }

            Section {
                if bookmark.tags.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("Bookmark Detail No Tags Added Title")
                        } icon: {
                            YabaIconView(bundleKey: "tags")
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .foregroundStyle(folderAccent)
                        }
                    } description: {
                        Text("Bookmark Detail No Tags Added Description")
                    }
                } else {
                    ForEach(bookmark.tags) { tag in
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
                sectionHeader("Tags Title", icon: "tag-01")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }

    private var tocList: some View {
        Group {
            if tocItems.isEmpty {
                emptyStateContent(
                    icon: "left-to-right-list-triangle",
                    title: "Bookmark Detail No Table Of Contents Title",
                    message: "Bookmark Detail No Table Of Contents Message"
                )
            } else {
                List {
                    ForEach(flattenLinkmarkTocItems(tocItems)) { row in
                        Button {
                            onTocItemTap(row.item)
                        } label: {
                            HStack(spacing: 10) {
                                YabaIconView(bundleKey: tocHeadingIcon(level: row.item.level))
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(folderAccent)
                                Text(row.item.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.leading, CGFloat(row.depth * 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    @ViewBuilder
    private func metadataRow(_ key: LocalizedStringKey, icon: String, value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .top, spacing: 12) {
                YabaIconView(bundleKey: icon)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(folderAccent)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body)
                }
            }
        }
    }

    private func infoTextRow(
        icon: String,
        value: String?,
        emptyPlaceholder: LocalizedStringKey? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            YabaIconView(bundleKey: icon)
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

    private func infoMetadataRow(icon: String, title: LocalizedStringKey, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                YabaIconView(bundleKey: icon)
                    .frame(width: 22, height: 22)
                    .foregroundStyle(folderAccent)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(value)
                .font(.footnote.weight(.semibold))
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey, icon: String) -> some View {
        Label {
            Text(title)
        } icon: {
            YabaIconView(bundleKey: icon)
                .frame(width: 20, height: 20)
                .foregroundStyle(folderAccent)
        }
    }

    private func emptyStateContent(
        icon: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey
    ) -> some View {
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
            Text(message)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func tocHeadingIcon(level: Int) -> String {
        switch level {
        case 1: "heading-01"
        case 2: "heading-02"
        case 3: "heading-03"
        case 4: "heading-04"
        case 5: "heading-05"
        default: "heading-06"
        }
    }
}
