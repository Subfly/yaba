//
//  Created by Ali Taha on 20.04.2026.
//

import SwiftData
import SwiftUI
import UIKit
import WebKit

/// SwiftData-driven link bookmark detail + Milkdown readable host.
struct LinkmarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.colorScheme)
    private var colorScheme

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = LinkmarkDetailStateMachine()

    @State
    private var sheetTab: LinkmarkDetailSheetTab = .info
    
    @State
    private var documentReloadToken = UUID()

    @State
    private var showDetailSheet = false
    
    @State
    private var showEditSheet = false

    @State
    private var showMoveSheet = false

    @State
    private var showShareURLSheet = false
    
    @State
    private var showReminderSheet = false

    @State
    private var showDeleteAlert = false

    @State
    private var reminderDraft = Date().addingTimeInterval(3600)

    @State
    private var activityItems: [Any] = []

    @State
    private var showActivitySheet = false

    @State
    private var markdownExportRequest: MarkdownExportRequest?

    @State
    private var showMarkdownExportDirectoryPicker = false

    @State
    private var annotationSheetMode: AnnotationCreationSheetMode?

    @State
    private var readerRuntime: WKWebViewRuntime?

    @State
    private var readerChromeVisible = true

    @State
    private var readerCanAnnotate = false

    @State
    private var tocNavigateItemId: String?

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
        .onChange(of: bookmark?.linkDetail?.markdown) { _, _ in
            documentReloadToken = UUID()
        }
        .onChange(of: bookmark?.linkDetail?.inlineAssets.count) { _, _ in
            documentReloadToken = UUID()
        }
        .onChange(of: documentReloadToken) { _, _ in
            readerChromeVisible = true
        }
        .sheet(isPresented: $showDetailSheet) {
            if let bm = bookmark {
                LinkmarkDetailInfoSheet(
                    bookmark: bm,
                    tocItems: LinkmarkMarkdownTocBuilder.build(from: bm.linkDetail?.markdown ?? ""),
                    folderAccent: folderColor(for: bm),
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
                    },
                    selectedTab: $sheetTab,
                    onScrollToAnnotation: { annotationId in
                        showDetailSheet = false
                        Task { await machine.send(.onScrollToAnnotation(annotationId: annotationId)) }
                    },
                    onEditAnnotation: { annotationId in
                        presentAnnotationSheetAfterClosingDetail(annotationId: annotationId)
                    },
                    onDeleteAnnotation: { annotationId in
                        showDetailSheet = false
                        Task { await deleteReadableAnnotation(annotationId: annotationId) }
                    },
                    onTocItemTap: { item in
                        tocNavigateItemId = item.id
                        showDetailSheet = false
                    }
                )
            }
        }
        .sheet(item: $annotationSheetMode) { mode in
            AnnotationCreationSheet(mode: mode) { outcome in
                annotationSheetMode = nil
                switch outcome {
                case .cancelled:
                    break
                case .persisted:
                    if case let .edit(ann) = mode {
                        Task { await syncMarkdownDirectiveColorAfterEdit(annotationId: ann.annotationId) }
                    }
                case let .readableCreateRequested(annotationId, request):
                    Task { await commitReadableAnnotationCreate(annotationId: annotationId, request: request) }
                case let .readableDeleteRequested(annotationId):
                    Task { await deleteReadableAnnotation(annotationId: annotationId) }
                }
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
                    SelectFolderContent(
                        mode: .bookmarksMove,
                        contextFolderId: bm.folder?.folderId,
                        contextBookmarkIds: [bm.bookmarkId],
                        onPick: { target in
                            if let target {
                                AllBookmarksManager.queueMoveBookmarksToFolder(
                                    bookmarkIds: [bm.bookmarkId],
                                    targetFolderId: target
                                )
                            }
                            showMoveSheet = false
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showShareURLSheet) {
            if let urlStr = bookmark?.linkDetail?.url, let u = URL(string: urlStr) {
                ShareSheet(bookmarkLink: u)
            }
        }
        .sheet(isPresented: $showActivitySheet) {
            ActivityItemsShareSheet(items: activityItems)
        }
        .sheet(isPresented: $showMarkdownExportDirectoryPicker) {
            MarkdownExportDirectoryPicker { url in
                Task { @MainActor in
                    finalizeMarkdownExport(selectedDirectory: url)
                }
            }
        }
        .sheet(isPresented: $showReminderSheet) {
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
                        Button("Cancel") { showReminderSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
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
                            showReminderSheet = false
                        }
                    }
                }
            }
        }
        .alert("Delete Bookmark Title", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await machine.send(.onDeleteBookmark(bookmarkId: bookmarkId))
                    dismiss()
                }
            }
        } message: {
            if let bm = bookmark {
                Text("Delete Content Message \(bm.label)")
            }
        }
    }

    private var bookmark: YabaBookmark? { bookmarks.first }

    @ViewBuilder
    private func mainContent(for bm: YabaBookmark) -> some View {
        let hasReadable = linkHasReadableContent(bm)
        let folderTint = folderColor(for: bm)
        ZStack(alignment: .bottom) {
            if hasReadable {
                linkmarkReaderBackground(readerTheme: machine.state.readerTheme)
                    .ignoresSafeArea()

                LinkmarkReadItLaterWebView(
                    markdown: readableBodyString(for: bm),
                    inlineAssets: readerInlineAssets(for: bm),
                    readerPreferences: ReaderPreferences(
                        theme: machine.state.readerTheme,
                        fontSize: machine.state.readerFontSize,
                        lineHeight: machine.state.readerLineHeight
                    ),
                    appearance: .auto,
                    annotationsJson: annotationsJson(for: bm),
                    tocNavigateItemId: $tocNavigateItemId,
                    scrollToAnnotationId: Binding(
                        get: { machine.state.scrollToAnnotationId },
                        set: { newValue in
                            if newValue == nil {
                                Task { await machine.send(.onClearScrollToAnnotation) }
                            }
                        }
                    ),
                    onHostEvent: { event in
                        handleReaderHostEvent(event)
                    },
                    onInlineLinkTap: { event in
                        guard let url = URL(string: event.url) else { return }
                        UIApplication.shared.open(url)
                    },
                    onAnnotationTap: { annotationId in
                        openAnnotationEditor(annotationId: annotationId)
                    },
                    onScrollShowChrome: {
                        readerChromeVisible = true
                    },
                    onScrollHideChrome: {
                        readerChromeVisible = false
                    },
                    onRuntimeReady: { runtime in
                        readerRuntime = runtime
                    }
                )
                .ignoresSafeArea()
                .id(documentReloadToken)
                .preferredColorScheme(effectiveReaderColorScheme(readerTheme: machine.state.readerTheme))

                LinkmarkReaderFloatingToolbar(
                    folderAccent: folderTint,
                    isVisible: readerChromeVisible || readerCanAnnotate,
                    canAnnotate: readerCanAnnotate,
                    readerTheme: machine.state.readerTheme,
                    readerFontSize: machine.state.readerFontSize,
                    readerLineHeight: machine.state.readerLineHeight,
                    onSelectTheme: { theme in
                        Task { await machine.send(.onSetReaderTheme(theme)) }
                    },
                    onSelectFontSize: { fontSize in
                        Task { await machine.send(.onSetReaderFontSize(fontSize)) }
                    },
                    onSelectLineHeight: { lineHeight in
                        Task { await machine.send(.onSetReaderLineHeight(lineHeight)) }
                    },
                    onStickyNote: openAnnotationCreator
                )
                .padding(.bottom, 14)
            } else {
                LinkmarkNoReadableVersionView(accent: folderTint)
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        homeToolbarIcon("arrow-left-01")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDetailSheet = true
                    } label: {
                        homeToolbarIcon("information-circle")
                    }
                }
                if #available(iOS 26, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    overflowMenu(for: bm)
                }
            }
            .tint(folderTint)
    }

    private func folderColor(for bm: YabaBookmark) -> Color {
        bm.folder?.color.getUIColor() ?? .accentColor
    }

    private func linkHasReadableContent(_ bm: YabaBookmark) -> Bool {
        let md = bm.linkDetail?.markdown ?? ""
        return !md.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func readableBodyString(for bm: YabaBookmark) -> String {
        bm.linkDetail?.markdown ?? ""
    }

    private func readerInlineAssets(for bm: YabaBookmark) -> [LinkmarkInlineAssetPayload] {
        (bm.linkDetail?.inlineAssets ?? []).compactMap { item in
            guard let bytes = item.bytes, !bytes.isEmpty else { return nil }
            return LinkmarkInlineAssetPayload(
                assetId: item.assetId,
                pathExtension: normalizedInlineAssetPathExtension(item.pathExtension),
                bytes: bytes
            )
        }
    }

    private func normalizedInlineAssetPathExtension(_ raw: String) -> String {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        if normalized == "jpg" { return "jpeg" }
        return normalized.isEmpty ? "jpeg" : normalized
    }

    @ViewBuilder
    private func linkmarkReaderBackground(readerTheme: ReaderTheme) -> some View {
        if readerTheme == .sepia {
            Color(red: 0.98, green: 0.95, blue: 0.88)
        } else {
            Color(.systemBackground)
        }
    }

    private func effectiveReaderColorScheme(readerTheme: ReaderTheme) -> ColorScheme {
        switch readerTheme {
        case .light, .sepia: return .light
        case .dark: return .dark
        case .system: return colorScheme
        }
    }

    private func linkSourceURL(for bm: YabaBookmark) -> URL? {
        guard let s = bm.linkDetail?.url.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return URL(string: s)
    }

    private func annotationsJson(for bm: YabaBookmark) -> String {
        let ann = bm.annotations.filter { $0.type == .readable }
        return AnnotationRenderingPayloadBuilder.readableJSON(from: ann)
    }

    private func commitReadableAnnotationCreate(annotationId: String, request: AnnotationReadableCreateRequest) async {
        guard let bm = bookmark else { return }
        let md = bm.linkDetail?.markdown ?? ""
        let context = prefixSuffix(from: request.selectionDraft)
        do {
            let updated = try LinkmarkReadableMarkdownAnnotations.insertDirective(
                markdown: md,
                selectedText: request.selectionDraft.quoteText ?? "",
                prefixText: context.prefix,
                suffixText: context.suffix,
                annotationId: annotationId,
                color: request.colorRole
            )
            await machine.send(
                .onAnnotationReadableCreateCommitted(request: request, annotationId: annotationId, html: updated)
            )
        } catch {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Annotation Selection Required Message"),
                iconType: .error,
                duration: .short
            )
        }
    }

    private func deleteReadableAnnotation(annotationId: String) async {
        guard let bm = bookmark else { return }
        let md = bm.linkDetail?.markdown ?? ""
        let updated = LinkmarkReadableMarkdownAnnotations.removeDirective(markdown: md, annotationId: annotationId)
        await machine.send(.onAnnotationReadableDeleteCommitted(annotationId: annotationId, html: updated))
    }

    private func syncMarkdownDirectiveColorAfterEdit(annotationId: String) async {
        guard let bm = bookmark,
              let ann = bm.annotations.first(where: { $0.annotationId == annotationId }),
              ann.type == .readable
        else {
            return
        }
        let md = bm.linkDetail?.markdown ?? ""
        let updated = LinkmarkReadableMarkdownAnnotations.setDirectiveColor(
            markdown: md,
            annotationId: annotationId,
            color: ann.colorRole
        )
        guard updated != md else { return }
        ReadableContentManager.queueUpdateReadableBodyFromWebEditor(bookmarkId: bm.bookmarkId, html: updated)
    }

    private func makeReadableDraftFromPreviewSnapshot(json: String, bookmarkId: String) -> ReadableSelectionDraft? {
        guard let data = json.data(using: .utf8),
              let dto = try? JSONDecoder().decode(PreviewSelectionSnapshotDTO.self, from: data)
        else {
            return nil
        }
        let text = dto.selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let extras = PreviewSelectionExtras(prefixText: dto.prefixText, suffixText: dto.suffixText)
        let extrasJson = (try? JSONEncoder().encode(extras)).flatMap { String(data: $0, encoding: .utf8) }
        return ReadableSelectionDraft(
            bookmarkId: bookmarkId,
            quoteText: text,
            extrasJson: extrasJson,
            annotationType: .readable
        )
    }

    private func prefixSuffix(from draft: ReadableSelectionDraft) -> (prefix: String?, suffix: String?) {
        guard let raw = draft.extrasJson,
              let data = raw.data(using: .utf8),
              let e = try? JSONDecoder().decode(PreviewSelectionExtras.self, from: data)
        else {
            return (nil, nil)
        }
        return (e.prefixText, e.suffixText)
    }

    private func openAnnotationCreator() {
        guard let bm = bookmark else { return }
        guard linkHasReadableContent(bm) else { return }
        Task { @MainActor in
            var draft: ReadableSelectionDraft?
            for _ in 0 ..< 6 {
                if let runtime = readerRuntime {
                    let json = (try? await runtime.evaluateJavaScriptStringResult(WebPreviewBridgeScripts.getSelectionSnapshot())) ?? ""
                    draft = makeReadableDraftFromPreviewSnapshot(json: json, bookmarkId: bm.bookmarkId)
                }
                if draft != nil { break }
                try? await Task.sleep(nanoseconds: 80_000_000)
            }
            if let draft {
                annotationSheetMode = .create(draft)
            } else {
                CoreToastManager.shared.show(
                    message: LocalizedStringKey("Annotation Selection Required Message"),
                    iconType: .error,
                    duration: .short
                )
            }
        }
    }

    private func handleReaderHostEvent(_ event: WebHostEvent) {
        switch event {
        case let .readerMetrics(ev):
            readerCanAnnotate = ev.canCreateAnnotation
        case let .initialContentLoad(result):
            let resultJson = (result == .loaded) ? #"{"result":"loaded"}"# : #"{"result":"error"}"#
            Task {
                await machine.send(.onReaderWebInitialContentLoad(resultJson: resultJson))
            }
        default:
            break
        }
    }

    private func openAnnotationEditor(annotationId: String) {
        guard let ann = bookmark?.annotations.first(where: { $0.annotationId == annotationId }) else { return }
        annotationSheetMode = .edit(ann)
    }

    private func presentAnnotationSheetAfterClosingDetail(annotationId: String) {
        guard let ann = bookmark?.annotations.first(where: { $0.annotationId == annotationId }) else { return }
        showDetailSheet = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            annotationSheetMode = .edit(ann)
        }
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
            if let urlStr = bm.linkDetail?.url, let u = URL(string: urlStr) {
                Button {
                    UIApplication.shared.open(u)
                } label: {
                    overflowMenuItemLabel("Bookmark Detail Open Link Action", icon: "link-04")
                }
                .tint(YabaColor.green.getUIColor())
            }
            Button {
                showEditSheet = true
            } label: {
                overflowMenuItemLabel("Edit", icon: "edit-02")
            }
            .tint(YabaColor.orange.getUIColor())
            Button {
                showMoveSheet = true
            } label: {
                overflowMenuItemLabel("Move", icon: "arrow-move-up-right")
            }
            .tint(YabaColor.teal.getUIColor())
            Button {
                AllBookmarksManager.queueToggleBookmarkPinned(bookmarkId: bm.bookmarkId)
            } label: {
                overflowMenuItemLabel(
                    bm.isPinned ? "Bookmark Detail Unpin Action" : "Bookmark Detail Pin Action",
                    icon: bm.isPinned ? "pin" : "pin-off"
                )
            }
            .tint(YabaColor.yellow.getUIColor())
            Menu {
                Button {
                    Task { @MainActor in
                        startMarkdownExport(markdown: readableBodyString(for: bm), bookmark: bm)
                    }
                } label: {
                    overflowMenuItemLabel(
                        "Bookmark Detail Export Format Markdown Title",
                        icon: "document-attachment"
                    )
                }
                .tint(YabaColor.gray.getUIColor())
                Button {
                    
                } label: {
                    overflowMenuItemLabel(
                        "Bookmark Detail Export Format PDF Title",
                        icon: "pdf-02"
                    )
                }
                .tint(YabaColor.red.getUIColor())
            } label: {
                overflowMenuItemLabel("Bookmark Detail Export Menu Title", icon: "download-01")
            }
            .tint(YabaColor.blue.getUIColor())
            if machine.state.reminderDate == nil {
                Button {
                    showReminderSheet = true
                } label: {
                    overflowMenuItemLabel("Remind Me", icon: "notification-01")
                }
                .tint(YabaColor.yellow.getUIColor())
            }
            Button {
                showShareURLSheet = true
            } label: {
                overflowMenuItemLabel("Share", icon: "share-03")
            }
            .tint(YabaColor.indigo.getUIColor())
            Divider()
            if machine.state.reminderDate != nil {
                Button {
                    Task { await machine.send(.onCancelReminder) }
                } label: {
                    overflowMenuItemLabel(
                        "Bookmark Detail Cancel Reminder Action",
                        icon: "notification-off-03"
                    )
                }
                .tint(YabaColor.red.getUIColor())
            }
            Button {
                showDeleteAlert = true
            } label: {
                overflowMenuItemLabel("Delete", icon: "delete-02")
            }
            .tint(YabaColor.red.getUIColor())
        } label: {
            homeToolbarIcon("more-horizontal-circle-02")
        }
    }

    /// Same template size as `HomeCollectionView` section headers and `LinkmarkReaderFloatingToolbar` glyphs (22×22).
    @ViewBuilder
    private func homeToolbarIcon(_ bundleKey: String) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .frame(width: 22, height: 22)
    }

    /// Plain label; color the row with `.tint(...)` on the `Button` or `Menu` (same pattern as `FolderDetailView` overflow actions).
    @ViewBuilder
    private func overflowMenuItemLabel(_ key: LocalizedStringKey, icon: String) -> some View {
        Label {
            Text(key)
        } icon: {
            YabaIconView(bundleKey: icon)
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }

    private func startMarkdownExport(markdown: String, bookmark: YabaBookmark?) {
        guard let bookmark else { return }
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
            return
        }
        let inlineSources: [MarkdownExportInlineSource] = (bookmark.linkDetail?.inlineAssets ?? []).compactMap { item in
            guard let bytes = item.bytes, !bytes.isEmpty else { return nil }
            return MarkdownExportInlineSource(assetId: item.assetId, pathExtension: item.pathExtension, bytes: bytes)
        }
        markdownExportRequest = MarkdownExportRequest(
            markdown: trimmed + "\n",
            baseFolderName: MarkdownExportSupport.sanitizeBaseFolderName(bookmark.label),
            assets: MarkdownExportSupport.exportAssets(from: inlineSources)
        )
        showMarkdownExportDirectoryPicker = true
    }

    private func finalizeMarkdownExport(selectedDirectory: URL?) {
        defer { markdownExportRequest = nil }
        guard let selectedDirectory, let request = markdownExportRequest else { return }
        let didWrite = MarkdownExportSupport.writeBundle(request, into: selectedDirectory)
        if !didWrite {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
        }
    }
}

private struct PreviewSelectionSnapshotDTO: Codable {
    let selectedText: String
    let prefixText: String?
    let suffixText: String?
}

private struct PreviewSelectionExtras: Codable {
    let prefixText: String?
    let suffixText: String?
}

/// Same CUV pattern as the old reader-not-available empty state (legacy `ReaderView` was removed during the Darwin rebuild).
private struct LinkmarkNoReadableVersionView: View {
    let accent: Color

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("Reader Not Available Title")
                    .padding(.bottom)
            } icon: {
                YabaIconView(bundleKey: "cancel-square")
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(accent)
                    .padding(.top)
            }
        } description: {
            Text("Reader Not Available Description")
                .padding(
                    .horizontal,
                    UIDevice.current.userInterfaceIdiom == .pad ? 52 : 0
                )
        }
    }
}
