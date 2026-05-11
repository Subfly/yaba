//
//  Created by Ali Taha on 20.04.2026.
//

import SwiftData
import SwiftUI

/// SwiftData-driven link bookmark detail + Milkdown readable host.
struct LinkmarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void
    var showsBackButton: Bool = true

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.colorScheme)
    private var colorScheme

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = LinkmarkDetailStateMachine()

    @State
    private var reminderDraft = Date().addingTimeInterval(3600)

    @State
    private var activityItems: [Any] = []

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
                if bm.kind == .link {
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
            if let url = bookmark?.linkDetail?.url {
                await machine.send(.onLinkSourceUrl(url))
            }
        }
        .onChange(of: bookmark?.linkDetail?.url) { _, newUrl in
            guard let newUrl else { return }
            Task { await machine.send(.onLinkSourceUrl(newUrl)) }
        }
        .sheet(isPresented: machine.showDetailSheetBinding) {
            if let bm = bookmark {
                LinkmarkDetailInfoSheet(
                    bookmark: bm,
                    folderAccent: BookmarkDetailChrome.folderAccent(for: bm),
                    reminderDate: machine.state.reminderDate,
                    onDeleteReminder: {
                        Task { await machine.send(.onCancelReminder) }
                    },
                    onOpenFolder: { folderId in
                        machine.apply { $0.showDetailSheet = false }
                        onOpenFolder(folderId)
                    },
                    onOpenTag: { tagId in
                        machine.apply { $0.showDetailSheet = false }
                        onOpenTag(tagId)
                    }
                )
            }
        }
        .sheet(isPresented: machine.showEditSheetBinding) {
            if let bm = bookmark {
                BookmarkFlowSheet(context: BookmarkFlowContext.edit(bookmarkId: bm.bookmarkId))
            }
        }
        .sheet(isPresented: machine.showMoveSheetBinding) {
            if let bm = bookmark {
                NavigationStack {
                    BookmarkDetailMoveToFolderPickContent(
                        bookmarkId: bm.bookmarkId,
                        contextFolderId: bm.folder?.folderId,
                        onComplete: { machine.apply { $0.showMoveSheet = false } }
                    )
                }
            }
        }
        .sheet(isPresented: machine.showShareURLSheetBinding) {
            if let urlStr = bookmark?.linkDetail?.url, let u = URL(string: urlStr) {
                ShareSheet(bookmarkLink: u)
            }
        }
        .sheet(isPresented: machine.showActivitySheetBinding) {
            ActivityItemsShareSheet(items: activityItems)
        }
        .sheet(isPresented: machine.showMarkdownExportDirectoryPickerBinding) {
            ExportDirectoryPicker { url in
                Task { @MainActor in
                    machine.finalizeMarkdownExport(selectedDirectory: url)
                }
            }
        }
        .sheet(isPresented: machine.showReminderSheetBinding) {
            BookmarkDetailReminderPickerSheetContent(
                reminderDraft: $reminderDraft,
                onCancel: { machine.apply { $0.showReminderSheet = false } },
                onConfirm: {
                    Task {
                        await machine.send(.onRequestNotificationPermission)
                        await machine.send(
                            .onScheduleReminder(
                                fireAt: reminderDraft,
                                titleKey: "Reminder Default Title",
                                messageKey: "Reminder Default Body"
                            )
                        )
                    }
                    machine.apply { $0.showReminderSheet = false }
                }
            )
        }
        .bookmarkDetailDeleteBookmarkAlert(
            isPresented: machine.showDeleteAlertBinding,
            bookmarkLabel: bookmark?.label ?? "",
            onDelete: { await machine.send(.onDeleteBookmark(bookmarkId: bookmarkId)) },
            dismiss: dismiss
        )
    }

    private var bookmark: YabaBookmark? { bookmarks.first }

    @ViewBuilder
    private func mainContent(for bm: YabaBookmark) -> some View {
        let hasReadable = linkHasReadableContent(bm)
        let folderTint = BookmarkDetailChrome.folderAccent(for: bm)
        ZStack(alignment: .bottom) {
            if hasReadable {
                BookmarkDetailReaderChrome.readerSurfaceBackground(readerTheme: machine.state.readerTheme)
                    .ignoresSafeArea()

                LinkmarkReadItLaterWebView(
                    markdown: readableBodyString(for: bm),
                    inlineAssets: readerInlineAssets(for: bm),
                    readerPreferences: ReaderPreferences(
                        theme: machine.state.readerTheme,
                        fontSize: machine.state.readerFontSize,
                        lineHeight: machine.state.readerLineHeight
                    ),
                    readerColumnLayout: LinkmarkReaderDetailLayout.readerColumnLayout,
                    appearance: .auto,
                    onHostEvent: { event in
                        handleReaderHostEvent(event)
                    },
                    onInlineLinkTap: { event in
                        guard let url = URL(string: event.url) else { return }
                        UIApplication.shared.open(url)
                    },
                    onRuntimeReady: { _ in }
                )
                .ignoresSafeArea(edges: [.top, .bottom])
                .preferredColorScheme(
                    BookmarkDetailReaderChrome.preferredColorScheme(
                        readerTheme: machine.state.readerTheme,
                        userInterfaceColorScheme: colorScheme
                    )
                )
            } else {
                BookmarkDetailReaderChrome.linkReaderUnavailablePlaceholder(tint: folderTint)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsBackButton {
                BookmarkDetailPrimaryToolbarPieces.backDismissButton { dismiss() }
            }
            if hasReadable, !LinkmarkReaderDetailLayout.isIPhone {
                ToolbarItem(placement: .topBarTrailing) {
                    ReaderToolbarThemeMenu(
                        folderAccent: folderTint,
                        readerTheme: machine.state.readerTheme,
                        onSelectTheme: { theme in
                            Task { await machine.send(.onSetReaderTheme(theme)) }
                        },
                        menuIconPadding: 6
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ReaderToolbarFontMenu(
                        folderAccent: folderTint,
                        readerFontSize: machine.state.readerFontSize,
                        onSelectFontSize: { fontSize in
                            Task { await machine.send(.onSetReaderFontSize(fontSize)) }
                        },
                        menuIconPadding: 6
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ReaderToolbarLineHeightMenu(
                        folderAccent: folderTint,
                        readerLineHeight: machine.state.readerLineHeight,
                        onSelectLineHeight: { lineHeight in
                            Task { await machine.send(.onSetReaderLineHeight(lineHeight)) }
                        },
                        menuIconPadding: 6
                    )
                }
                BookmarkDetailPrimaryToolbarPieces.fixedTrailingToolbarSpacer()
            }
            if hasReadable, LinkmarkReaderDetailLayout.isIPhone {
                ToolbarItem(placement: .topBarTrailing) {
                    linkmarkReaderToolbarAppearanceRootMenu()
                }
                BookmarkDetailPrimaryToolbarPieces.fixedTrailingToolbarSpacer()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    machine.apply { $0.showDetailSheet = true }
                } label: {
                    BookmarkDetailHomeToolbarGlyph(bundleKey: "information-circle")
                }
            }
            BookmarkDetailPrimaryToolbarPieces.trailingOverflowChrome {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
    }

    @ViewBuilder
    private func linkmarkReaderToolbarAppearanceRootMenu() -> some View {
        Menu {
            Menu {
                ForEach(ReaderTheme.allCases, id: \.self) { t in
                    Button {
                        Task { await machine.send(.onSetReaderTheme(t)) }
                    } label: {
                        HStack {
                            if machine.state.readerTheme == t {
                                Image(systemName: "checkmark")
                            }
                            Text(t.getUITitle())
                        }
                    }
                }
            } label: {
                BookmarkDetailOverflowRowLabel(
                    title: "Markdown Preview Background Color Options Label",
                    iconBundleKey: "paint-bucket"
                )
            }
            Menu {
                ForEach(ReaderFontSize.allCases, id: \.self) { f in
                    Button {
                        Task { await machine.send(.onSetReaderFontSize(f)) }
                    } label: {
                        HStack {
                            if machine.state.readerFontSize == f {
                                Image(systemName: "checkmark")
                            }
                            Text(f.getUITitle())
                        }
                    }
                }
            } label: {
                BookmarkDetailOverflowRowLabel(
                    title: "Markdown Preview Font Size Options Label",
                    iconBundleKey: "text-font"
                )
            }
            Menu {
                ForEach(ReaderLineHeight.allCases, id: \.self) { lh in
                    Button {
                        Task { await machine.send(.onSetReaderLineHeight(lh)) }
                    } label: {
                        HStack {
                            if machine.state.readerLineHeight == lh {
                                Image(systemName: "checkmark")
                            }
                            Text(lh.getUITitle())
                        }
                    }
                }
            } label: {
                BookmarkDetailOverflowRowLabel(
                    title: "Markdown Preview Line Height Options Label",
                    iconBundleKey: "paragraph-spacing"
                )
            }
        } label: {
            BookmarkDetailHomeToolbarGlyph(bundleKey: "settings-05")
        }
    }


    private func linkHasReadableContent(_ bm: YabaBookmark) -> Bool {
        let md = bm.linkDetail?.markdown ?? ""
        return !md.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func readableBodyString(for bm: YabaBookmark) -> String {
        bm.linkDetail?.markdown ?? ""
    }

    private func readerInlineAssets(for bm: YabaBookmark) -> [YabaInlineAssetPayload] {
        (bm.linkDetail?.inlineAssets ?? []).compactMap { YabaInlineAssetPayload(inlineAsset: $0) }
    }

    private func linkSourceURL(for bm: YabaBookmark) -> URL? {
        guard let s = bm.linkDetail?.url.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return URL(string: s)
    }

    private func handleReaderHostEvent(_ event: WebHostEvent) {
        switch event {
        case let .initialContentLoad(result):
            let resultJson = (result == .loaded) ? #"{"result":"loaded"}"# : #"{"result":"error"}"#
            Task {
                await machine.send(.onReaderWebInitialContentLoad(resultJson: resultJson))
            }
        default:
            break
        }
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
            if let urlStr = bm.linkDetail?.url, let u = URL(string: urlStr) {
                Button {
                    UIApplication.shared.open(u)
                } label: {
                    BookmarkDetailOverflowRowLabel(
                        title: "Bookmark Detail Open Link Action",
                        iconBundleKey: "link-04"
                    )
                }
                .tint(YabaColor.green.getUIColor())
            }
            Button {
                machine.apply { $0.showEditSheet = true }
            } label: {
                BookmarkDetailOverflowRowLabel(title: "Edit", iconBundleKey: "edit-02")
            }
            .tint(YabaColor.orange.getUIColor())
            Button {
                machine.apply { $0.showMoveSheet = true }
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
                Task { @MainActor in
                    machine.startMarkdownExport(
                        markdown: readableBodyString(for: bm),
                        bookmarkLabel: bm.label,
                        inlineSources: markdownExportInlineSources(for: bm)
                    )
                }
            } label: {
                BookmarkDetailOverflowRowLabel(
                    title: "Bookmark Detail Export Format Markdown Title",
                    iconBundleKey: "document-attachment"
                )
            }
            .tint(YabaColor.gray.getUIColor())
            if machine.state.reminderDate == nil {
                Button {
                    machine.apply { $0.showReminderSheet = true }
                } label: {
                    BookmarkDetailOverflowRowLabel(title: "Remind Me", iconBundleKey: "notification-01")
                }
                .tint(YabaColor.yellow.getUIColor())
            }
            Button {
                machine.apply { $0.showShareURLSheet = true }
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
                machine.apply { $0.showDeleteAlert = true }
            } label: {
                BookmarkDetailOverflowRowLabel(title: "Delete", iconBundleKey: "delete-02")
            }
            .tint(YabaColor.red.getUIColor())
        } label: {
            BookmarkDetailHomeToolbarGlyph(bundleKey: "more-horizontal-circle-02")
        }
    }

    private func markdownExportInlineSources(for bm: YabaBookmark) -> [MarkdownExportInlineSource] {
        (bm.linkDetail?.inlineAssets ?? []).compactMap { item in
            guard let bytes = item.bytes, !bytes.isEmpty else { return nil }
            return MarkdownExportInlineSource(assetId: item.assetId, pathExtension: item.pathExtension, bytes: bytes)
        }
    }
}

// MARK: - Reader column (CSS in preview shell; WKWebView stays full-bleed)

private enum LinkmarkReaderDetailLayout {
    static var isIPhone: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }

    static var readerColumnLayout: ReaderViewportColumnLayout {
        #if os(macOS)
        ReaderViewportColumnLayout(maxWidthVWPercent: 70, horizontalPaddingPx: 16)
        #elseif targetEnvironment(macCatalyst)
        ReaderViewportColumnLayout(maxWidthVWPercent: 70, horizontalPaddingPx: 16)
        #elseif os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return ReaderViewportColumnLayout(maxWidthVWPercent: 90, horizontalPaddingPx: 16)
        default:
            return .fullWidth
        }
        #else
        .fullWidth
        #endif
    }
}
