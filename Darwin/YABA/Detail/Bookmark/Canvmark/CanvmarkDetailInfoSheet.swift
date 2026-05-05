//
//  CanvmarkDetailInfoSheet.swift
//  YABA
//

import SwiftUI
import UIKit

/// Info + assets sheet for canvas bookmarks (parity with ``NotemarkDetailInfoSheet``).
struct CanvmarkDetailInfoSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let bookmark: YabaBookmark
    let folderAccent: Color
    let reminderDate: Date?
    let onDeleteReminder: () -> Void
    let onDeleteAsset: (String) -> Void
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    @State
    private var selectedTab: SheetTab = .info

    @State
    private var assetDeleteAlertId: String?

    private enum SheetTab: Hashable {
        case info
        case assets
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Info")
                        .tag(SheetTab.info)
                    Text("Bookmark Detail Images Label")
                        .tag(SheetTab.assets)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Group {
                    switch selectedTab {
                    case .info:
                        infoList
                    case .assets:
                        assetsTabContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .alert(
                LocalizedStringKey("Bookmark Asset Image Delete Label"),
                isPresented: Binding(
                    get: { assetDeleteAlertId != nil },
                    set: { newValue in
                        if !newValue { assetDeleteAlertId = nil }
                    }
                )
            ) {
                Button(role: .cancel) {
                    assetDeleteAlertId = nil
                } label: {
                    Text("Cancel")
                }
                Button(role: .destructive) {
                    if let id = assetDeleteAlertId {
                        onDeleteAsset(id)
                    }
                    assetDeleteAlertId = nil
                } label: {
                    Text(LocalizedStringKey("Delete"))
                }
            } message: {
                Text(LocalizedStringKey("Bookmark Asset Image Delete Message"))
            }
        }
    }

    private var infoList: some View {
        List {
            Section {
                infoTextRow(
                    icon: "text",
                    value: bookmark.label
                )
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

    private var assetsTabContent: some View {
        let payloads = canvmarkAssetPayloads
        return Group {
            if payloads.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("Bookmark Detail No Images Label")
                    } icon: {
                        YabaIconView(bundleKey: "image-delete-02")
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundStyle(folderAccent)
                    }
                } description: {
                    Text("Bookmark Detail No Images Description")
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: assetGridColumns, alignment: .leading, spacing: 12) {
                        ForEach(payloads, id: \.assetId) { payload in
                            assetCell(payload)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var canvmarkAssetPayloads: [YabaInlineAssetPayload] {
        (bookmark.canvasDetail?.inlineAssets ?? []).compactMap { YabaInlineAssetPayload(inlineAsset: $0) }
    }

    private var assetGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 280), spacing: 12, alignment: .top)]
    }

    @ViewBuilder
    private func assetCell(_ payload: YabaInlineAssetPayload) -> some View {
        Button {
            copyAssetIdToClipboard(payload.assetId, dismissSheetAfter: true)
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .overlay {
                    if let ui = UIImage(data: payload.bytes) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        ZStack {
                            folderAccent.opacity(0.12)
                            YabaIconView(bundleKey: "image-03")
                                .frame(width: 48, height: 48)
                                .foregroundStyle(folderAccent.opacity(0.7))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                copyAssetIdToClipboard(payload.assetId, dismissSheetAfter: false)
            } label: {
                Label {
                    Text(LocalizedStringKey("Bookmark Asset Image Copy Action Label"))
                } icon: {
                    YabaIconView(bundleKey: "copy-01")
                        .scaledToFit()
                }
            }
            .tint(YabaColor.teal.getUIColor())
            Divider()
            Button(role: .destructive) {
                assetDeleteAlertId = payload.assetId
            } label: {
                VStack {
                    YabaIconView(bundleKey: "delete-02")
                    Text(LocalizedStringKey("Delete"))
                }
            }
            .tint(.red)
        }
    }

    private func copyAssetIdToClipboard(_ assetId: String, dismissSheetAfter: Bool) {
        UIPasteboard.general.string = assetId
        CoreToastManager.shared.show(
            message: LocalizedStringKey("Bookmark Asset Image Copy To Clipboard Success Message"),
            iconType: .success,
            duration: .short
        )
        if dismissSheetAfter { dismiss() }
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
}
