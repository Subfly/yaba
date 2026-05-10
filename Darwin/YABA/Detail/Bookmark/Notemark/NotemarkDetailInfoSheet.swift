//
//  NotemarkDetailInfoSheet.swift
//  YABA
//

import SwiftData
import SwiftUI

struct NotemarkDetailInfoSheet: View {
    @Environment(\.dismiss)
    private var dismiss

    let bookmark: YabaBookmark
    let folderAccent: Color
    let reminderDate: Date?
    let onDeleteReminder: () -> Void
    let onDeleteInlineAsset: (String) -> Void
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    @State
    private var selectedTab: SheetTab = .info

    @State
    private var inlineAssetDeleteAlertAssetId: String?

    private enum SheetTab: Hashable {
        case info
        case images
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Info")
                        .tag(SheetTab.info)
                    Text("Bookmark Detail Images Label")
                        .tag(SheetTab.images)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Group {
                    switch selectedTab {
                    case .info:
                        infoList
                    case .images:
                        imagesTabContent
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
                    get: { inlineAssetDeleteAlertAssetId != nil },
                    set: { newValue in
                        if !newValue { inlineAssetDeleteAlertAssetId = nil }
                    }
                )
            ) {
                Button(role: .cancel) {
                    inlineAssetDeleteAlertAssetId = nil
                } label: {
                    Text("Cancel")
                }
                Button(role: .destructive) {
                    if let id = inlineAssetDeleteAlertAssetId {
                        onDeleteInlineAsset(id)
                    }
                    inlineAssetDeleteAlertAssetId = nil
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
        .bookmarkDetailInfoListSurfaceOnly()
    }

    private var imagesTabContent: some View {
        let payloads = notemarkInlineImagePayloads
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
                    LazyVGrid(columns: inlineImageGridColumns, alignment: .leading, spacing: 12) {
                        ForEach(payloads, id: \.assetId) { payload in
                            notemarkInlineImageCell(payload)
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var notemarkInlineImagePayloads: [YabaInlineAssetPayload] {
        (bookmark.noteDetail?.inlineAssets ?? []).compactMap { YabaInlineAssetPayload(inlineAsset: $0) }
    }

    private var inlineImageGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 280), spacing: 12, alignment: .top)]
    }

    @ViewBuilder
    private func notemarkInlineImageCell(_ payload: YabaInlineAssetPayload) -> some View {
        Button {
            copyInlineAssetIdToClipboard(payload.assetId, dismissSheetAfter: true)
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
                copyInlineAssetIdToClipboard(payload.assetId, dismissSheetAfter: false)
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
                inlineAssetDeleteAlertAssetId = payload.assetId
            } label: {
                VStack {
                    YabaIconView(bundleKey: "delete-02")
                    Text(LocalizedStringKey("Delete"))
                }
            }
            .tint(.red)
        }
    }

    private func copyInlineAssetIdToClipboard(_ assetId: String, dismissSheetAfter: Bool) {
        UIPasteboard.general.string = assetId
        CoreToastManager.shared.show(
            message: LocalizedStringKey("Bookmark Asset Image Copy To Clipboard Success Message"),
            iconType: .success,
            duration: .short
        )
        if dismissSheetAfter { dismiss() }
    }
}
