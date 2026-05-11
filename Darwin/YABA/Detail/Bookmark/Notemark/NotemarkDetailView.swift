//
//  NotemarkDetailView.swift
//  YABA
//

import SwiftData
import SwiftUI
import WebKit
import PhotosUI

/// SwiftData-driven note bookmark detail + CodeMirror editor host (`editor.html`).
/// Sheet/export state lives on ``NotemarkDetailStateMachine`` (parity with ``LinkmarkDetailView`` / ``LinkmarkDetailStateMachine``).
struct NotemarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void
    let onOpenBookmark: (String) -> Void
    var showsBackButton: Bool = true

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.colorScheme)
    private var colorScheme

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = NotemarkDetailStateMachine()

    @State
    private var reminderDraft = Date().addingTimeInterval(3600)

    @State
    private var editorRuntime: WKWebViewRuntime?

    @State
    private var previewRuntime: WKWebViewRuntime?

    @State
    private var previewSurfaceMarkdown: String = ""

    @State
    private var editorScrollHydrate = NotemarkWebScrollHydrate.inactive

    @State
    private var previewScrollHydrate = NotemarkWebScrollHydrate.inactive

    @State
    private var isSoftwareKeyboardVisible = false

    @State
    private var showAddLinkSheet = false

    @State
    private var addLinkSheetMode: AddLinkSheetMode = .link

    @State
    private var showAddTableSheet = false

    @State
    private var showAddMentionSheet = false

    @State
    private var notemarkGalleryPhotoItem: PhotosPickerItem?

    #if !targetEnvironment(macCatalyst)
    @State
    private var showNotemarkCameraCapture = false
    #endif

    @State
    private var highlightColorMarkEdit: HighlightColorMarkTapEvent?

    @State
    private var previewHighlightMarkEdit: PreviewHighlightMarkTapEvent?

    @State
    private var highlightColorPick: YabaColor = .yellow

    @State
    private var showHighlightColorSheet = false

    init(
        bookmarkId: String,
        onOpenFolder: @escaping (String) -> Void = { _ in },
        onOpenTag: @escaping (String) -> Void = { _ in },
        onOpenBookmark: @escaping (String) -> Void = { _ in },
        showsBackButton: Bool = true
    ) {
        self.bookmarkId = bookmarkId
        self.onOpenFolder = onOpenFolder
        self.onOpenTag = onOpenTag
        self.onOpenBookmark = onOpenBookmark
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
                if bm.kind == .note {
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
        }
        .sheet(isPresented: machine.showDetailSheetBinding) {
            if let bm = bookmark {
                NotemarkDetailInfoSheet(
                    bookmark: bm,
                    folderAccent: BookmarkDetailChrome.folderAccent(for: bm),
                    reminderDate: machine.state.reminderDate,
                    onDeleteReminder: {
                        Task { await machine.send(.onCancelReminder) }
                    },
                    onDeleteInlineAsset: { assetId in
                        Task { await machine.send(.onDeleteNoteInlineAsset(bookmarkId: bm.bookmarkId, assetId: assetId)) }
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
                                titleKey: "Reminder Default Title",
                                messageKey: "Reminder Default Body",
                                fireAt: reminderDraft
                            )
                        )
                    }
                    machine.apply { $0.showReminderSheet = false }
                }
            )
        }
        .sheet(isPresented: $showAddLinkSheet) {
            NavigationStack {
                AddLinkSheet(mode: addLinkSheetMode) { text, url in
                    switch addLinkSheetMode {
                    case .link:
                        dispatchEditorCommand(YabaEditorDispatchPayload.insertLink(text: text, url: url))
                    case .image:
                        dispatchEditorCommand(YabaEditorDispatchPayload.insertLink(text: text, url: url, asImage: true))
                    }
                    showAddLinkSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddTableSheet) {
            NavigationStack {
                AddTableSheet { rows, cols in
                    dispatchEditorCommand(YabaEditorDispatchPayload.insertTable(rows: rows, cols: cols, withHeaderRow: false))
                    showAddTableSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddMentionSheet) {
            NavigationStack {
                AddMentionSheet(excludeBookmarkId: bookmarkId) { text, url in
                    dispatchEditorCommand(YabaEditorDispatchPayload.insertLink(text: text, url: url))
                    showAddMentionSheet = false
                }
            }
        }
        #if !targetEnvironment(macCatalyst)
        .fullScreenCover(isPresented: $showNotemarkCameraCapture) {
            CameraCapturePicker(
                onDismiss: { showNotemarkCameraCapture = false },
                onCapture: { data in
                    showNotemarkCameraCapture = false
                    guard let bm = bookmark else { return }
                    machine.handlePickedInlineImage(
                        data: data,
                        bookmarkId: bm.bookmarkId,
                        storedPathExtension: "png",
                        onAssetPersisted: { dispatchEditorCommand($0) }
                    )
                }
            )
            .ignoresSafeArea()
        }
        #endif
        .sheet(isPresented: $showHighlightColorSheet) {
            YabaColorPicker(selection: $highlightColorPick, onDismiss: {
                handleHighlightColorPickerDismissed()
            })
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
        let folderTint = BookmarkDetailChrome.folderAccent(for: bm)
        let markdown = noteMarkdown(for: bm)
        let readerPreferences = ReaderPreferences(
            theme: machine.state.readerTheme,
            fontSize: machine.state.readerFontSize,
            lineHeight: machine.state.readerLineHeight
        )
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ZStack {
                NotemarkEditorWebView(
                    markdown: markdown,
                    inlineAssets: notemarkPreviewInlineAssets(for: bm),
                    readerPreferences: readerPreferences,
                    appearance: .auto,
                    markdownScrollHydrate: editorScrollHydrate,
                    onHostEvent: { event in
                        handleEditorHostEvent(event)
                    },
                    onPersistDocument: { runtime in
                        await machine.persistEditorSnapshot(runtime: runtime)
                    },
                    onRuntimeReady: { runtime in
                        editorRuntime = runtime
                        sendSurfaceModeAnnouncement(to: runtime)
                    },
                    onHighlightColorMarkTap: { ev in
                        previewHighlightMarkEdit = nil
                        highlightColorPick = YabaColor.fromPaletteHexDigits(ev.hexDigits) ?? .blue
                        highlightColorMarkEdit = ev
                        showHighlightColorSheet = true
                    }
                )
                .id(bm.bookmarkId)
                .opacity(machine.state.surfaceMode == .editor ? 1 : 0)
                .allowsHitTesting(machine.state.surfaceMode == .editor)
                .accessibilityHidden(machine.state.surfaceMode != .editor)

                NotemarkPreviewWebView(
                    markdown: previewSurfaceMarkdown,
                    inlineAssets: notemarkPreviewInlineAssets(for: bm),
                    readerPreferences: readerPreferences,
                    appearance: .auto,
                    markdownScrollHydrate: previewScrollHydrate,
                    onHostEvent: { event in
                        handlePreviewHostEvent(event)
                    },
                    onInlineLinkTap: handlePreviewInlineLinkTap,
                    onRuntimeReady: { runtime in
                        previewRuntime = runtime
                        sendSurfaceModeAnnouncement(to: runtime)
                    },
                    onPreviewHighlightMarkTap: { ev in
                        highlightColorMarkEdit = nil
                        let digits = ev.hexDigits.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "#", with: "").lowercased()
                        highlightColorPick = YabaColor.fromPaletteHexDigits(digits) ?? .yellow
                        previewHighlightMarkEdit = ev
                        showHighlightColorSheet = true
                    },
                    onPreviewTaskCheckboxTap: { ev in
                        Task { @MainActor in
                            await applyPreviewTaskCheckboxToggle(bracketOpen: ev.bracketOpen, bookmarkId: bm.bookmarkId)
                        }
                    },
                )
                .id("\(bm.bookmarkId)-preview")
                .opacity(machine.state.surfaceMode == .preview ? 1 : 0)
                .allowsHitTesting(machine.state.surfaceMode == .preview)
                .accessibilityHidden(machine.state.surfaceMode != .preview)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: [.top, .bottom])
            .preferredColorScheme(
                BookmarkDetailReaderChrome.preferredColorScheme(
                    readerTheme: machine.state.readerTheme,
                    userInterfaceColorScheme: colorScheme
                )
            )

            HStack {
                Spacer(minLength: 0)
                NotemarkEditorFloatingToolbar(
                    folderAccent: folderTint,
                    isVisible: machine.state.surfaceMode == .editor,
                    showsDoneButton: machine.state.surfaceMode == .editor && isSoftwareKeyboardVisible,
                    onDispatch: { payload in
                        dispatchEditorCommand(payload)
                    },
                    onRequestAddLinkSheet: { mode in
                        addLinkSheetMode = mode
                        showAddLinkSheet = true
                    },
                    onRequestAddTableSheet: {
                        showAddTableSheet = true
                    },
                    onRequestAddMentionSheet: {
                        showAddMentionSheet = true
                    },
                    onDismissKeyboard: {
                        dismissNotemarkEditorKeyboard()
                    },
                    onRequestPickImageFromCamera: {
                        #if !targetEnvironment(macCatalyst)
                        showNotemarkCameraCapture = true
                        #endif
                    },
                    galleryPhotoItem: $notemarkGalleryPhotoItem
                )
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            guard machine.state.surfaceMode == .editor else { return }
            isSoftwareKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isSoftwareKeyboardVisible = false
        }
        .onChange(of: machine.state.surfaceMode) { _, newMode in
            if newMode != .editor {
                isSoftwareKeyboardVisible = false
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsBackButton {
                BookmarkDetailPrimaryToolbarPieces.backDismissButton { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    notemarkSurfaceModeToggleTapped(for: bm)
                } label: {
                    BookmarkDetailHomeToolbarGlyph(
                        bundleKey: machine.state.surfaceMode == .editor ? "edit-01" : "book-open-01"
                    )
                }
                .animation(.smooth, value: machine.selectedMode)
            }
            BookmarkDetailPrimaryToolbarPieces.fixedTrailingToolbarSpacer()
            BookmarkDetailPrimaryToolbarPieces.bookmarkInfoSheetGlyphButton {
                machine.apply { $0.showDetailSheet = true }
            }
            BookmarkDetailPrimaryToolbarPieces.trailingOverflowChrome {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
        .onChange(of: notemarkGalleryPhotoItem) { _, new in
            Task {
                guard let new else { return }
                guard let data = try? await new.loadTransferable(type: Data.self) else {
                    await MainActor.run { notemarkGalleryPhotoItem = nil }
                    return
                }
                await MainActor.run {
                    machine.handlePickedInlineImage(
                        data: data,
                        bookmarkId: bm.bookmarkId,
                        onAssetPersisted: { dispatchEditorCommand($0) }
                    )
                    notemarkGalleryPhotoItem = nil
                }
            }
        }
    }


    private func noteMarkdown(for bm: YabaBookmark) -> String {
        guard let data = bm.noteDetail?.payload?.documentBody,
              let s = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return s
    }

    private func notemarkPreviewInlineAssets(for bm: YabaBookmark) -> [YabaInlineAssetPayload] {
        (bm.noteDetail?.inlineAssets ?? []).compactMap { YabaInlineAssetPayload(inlineAsset: $0) }
    }

    private func handleEditorHostEvent(_ event: WebHostEvent) {
        switch event {
        case let .initialContentLoad(loadResult):
            let loadDetail = (loadResult == .loaded) ? #"{"result":"loaded"}"# : #"{"result":"error"}"#
            Task {
                await machine.send(.onWebInitialContentLoad(result: loadDetail))
            }
        default:
            break
        }
    }

    private func sendSurfaceModeAnnouncement(to runtime: WKWebViewRuntime) {
        Task { @MainActor in
            let mode = machine.state.surfaceMode
            let script = WebNotemarkBridgeScripts.dispatchSurfaceModeChange(mode)
            _ = try? await runtime.evaluateJavaScriptStringResult(script)
        }
    }

    private func notemarkSurfaceModeToggleTapped(for bm: YabaBookmark) {
        Task { @MainActor in
            await performNotemarkSurfaceModeToggle(bookmark: bm)
        }
    }

    @MainActor
    private func performNotemarkSurfaceModeToggle(bookmark bm: YabaBookmark) async {
        let nextMode: NotemarkDetailSurfaceMode = machine.state.surfaceMode == .editor ? .preview : .editor

        if machine.state.surfaceMode == .editor, nextMode == .preview {
            let fraction = await readEditorScrollFraction()
            let md = await readEditorMarkdown(bookmark: bm)
            previewSurfaceMarkdown = md
            previewScrollHydrate.enqueueFraction(fraction)
            await resignNotemarkEditorFirstResponder()
        } else if machine.state.surfaceMode == .preview, nextMode == .editor {
            let fraction = await readPreviewScrollFraction()
            editorScrollHydrate.enqueueFraction(fraction)
        }

        withAnimation(.smooth) {
            machine.apply { $0.surfaceMode = nextMode }
        }
        await broadcastSurfaceModeToBothRuntimes()
    }

    @MainActor
    private func broadcastSurfaceModeToBothRuntimes() async {
        let mode = machine.state.surfaceMode
        let script = WebNotemarkBridgeScripts.dispatchSurfaceModeChange(mode)
        if let editorRuntime {
            _ = try? await editorRuntime.evaluateJavaScriptStringResult(script)
        }
        if let previewRuntime {
            _ = try? await previewRuntime.evaluateJavaScriptStringResult(script)
        }
    }

    private func readEditorScrollFraction() async -> Double {
        guard let rt = editorRuntime else { return 0 }
        guard let js = try? await rt.evaluateJavaScriptStringResult(WebEditorBridgeScripts.getSyncedScrollFraction()) else {
            return 0
        }
        return parseNormalizedScrollFraction(js)
    }

    private func readPreviewScrollFraction() async -> Double {
        guard let rt = previewRuntime else { return 0 }
        guard let js = try? await rt.evaluateJavaScriptStringResult(WebPreviewBridgeScripts.getSyncedScrollFraction()) else {
            return 0
        }
        return parseNormalizedScrollFraction(js)
    }

    private func readEditorMarkdown(bookmark bm: YabaBookmark) async -> String {
        if let rt = editorRuntime,
           let md = try? await rt.evaluateJavaScriptStringResult(WebEditorBridgeScripts.getMarkdown())
        {
            return md
        }
        return noteMarkdown(for: bm)
    }

    private func parseNormalizedScrollFraction(_ js: String) -> Double {
        Double(js.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private func dispatchEditorCommand(_ payload: String) {
        Task { @MainActor in
            guard let rt = editorRuntime else { return }
            _ = try? await rt.evaluateJavaScriptStringResult(WebEditorBridgeScripts.dispatchCommand(payload))
        }
    }

    private func handleHighlightColorPickerDismissed() {
        showHighlightColorSheet = false

        let previewEv = previewHighlightMarkEdit
        previewHighlightMarkEdit = nil

        let editorEv = highlightColorMarkEdit
        highlightColorMarkEdit = nil

        let hex =
            highlightColorPick.canonicalHexDigits ?? YabaColor.yellow.canonicalHexDigits ?? "ffcc00"

        if let previewEv {
            Task { @MainActor in
                await applyPreviewHighlightRecolor(ev: previewEv, newHexDigits: hex, bookmarkId: bookmarkId)
            }
            return
        }

        guard let editorEv else { return }
        Task { @MainActor in
            guard let rt = editorRuntime else { return }
            _ = try? await rt.evaluateJavaScriptStringResult(
                WebEditorBridgeScripts.replaceHighlightColorMark(
                    from: editorEv.from,
                    to: editorEv.to,
                    hexDigits: hex
                )
            )
        }
    }

    @MainActor
    private func applyPreviewHighlightRecolor(ev: PreviewHighlightMarkTapEvent, newHexDigits: String, bookmarkId: String)
        async {
        var md = previewSurfaceMarkdown
        let ns = md as NSString
        let len = ns.length
        guard ev.syntaxStart >= 0, ev.syntaxEnd <= len, ev.innerStart >= 0, ev.innerEnd <= len,
              ev.innerEnd >= ev.innerStart, ev.syntaxEnd >= ev.innerEnd else { return }

        let inner = ns.substring(with: NSRange(location: ev.innerStart, length: ev.innerEnd - ev.innerStart))
        let replacement = "=={#\(newHexDigits)}" + inner + "=="
        md = ns.replacingCharacters(
            in: NSRange(location: ev.syntaxStart, length: ev.syntaxEnd - ev.syntaxStart),
            with: replacement
        )
        await persistMarkdownShared(md, bookmarkId: bookmarkId)
    }

    @MainActor
    private func applyPreviewTaskCheckboxToggle(bracketOpen: Int, bookmarkId: String) async {
        var md = previewSurfaceMarkdown
        let ns = md as NSString
        let len = ns.length
        guard bracketOpen >= 0, bracketOpen + 2 < len else { return }
        let innerRange = NSRange(location: bracketOpen + 1, length: 1)
        let ch = ns.substring(with: innerRange)
        let newCh = ch.lowercased() == "x" ? " " : "x"
        md = ns.replacingCharacters(in: innerRange, with: newCh)
        await persistMarkdownShared(md, bookmarkId: bookmarkId)
    }

    @MainActor
    private func persistMarkdownShared(_ md: String, bookmarkId: String) async {
        previewSurfaceMarkdown = md
        let data = Data(md.utf8)
        await machine.send(.saveDocument(bookmarkId: bookmarkId, data: data))
        if let rt = editorRuntime {
            _ = try? await rt.evaluateJavaScriptStringResult(WebEditorBridgeScripts.setMarkdown(md, assetsBaseUrl: nil))
        }
        if let pr = previewRuntime {
            _ = try? await pr.evaluateJavaScriptStringResult(WebPreviewBridgeScripts.setMarkdown(md))
        }
    }

    @MainActor
    private func resignNotemarkEditorFirstResponder() async {
        if let rt = editorRuntime {
            _ = try? await rt.evaluateJavaScriptStringResult(WebEditorBridgeScripts.unFocus())
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func dismissNotemarkEditorKeyboard() {
        Task { @MainActor in
            await resignNotemarkEditorFirstResponder()
        }
    }

    private func handlePreviewInlineLinkTap(_ event: InlineLinkTapEvent) {
        let trimmed = event.url.trimmingCharacters(in: .whitespacesAndNewlines)
        if let mentionId = bookmarkIdFromYabaMentionURL(trimmed), !mentionId.isEmpty {
            onOpenBookmark(mentionId)
            return
        }
        guard let url = URL(string: trimmed) else { return }
        UIApplication.shared.open(url)
    }

    /// `[label](yaba-mention://<bookmarkId>)` — host carries the bookmark id Swift stored when inserting mentions.
    private func bookmarkIdFromYabaMentionURL(_ raw: String) -> String? {
        guard let url = URL(string: raw), url.scheme?.lowercased() == "yaba-mention" else {
            return nil
        }

        if let host = url.host?.trimmingCharacters(in: .whitespacesAndNewlines), !host.isEmpty {
            let decoded = host.removingPercentEncoding ?? host
            return decoded.isEmpty ? nil : decoded
        }

        if let frag = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/", omittingEmptySubsequences: true).first {
            let s = String(frag).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty else { return nil }
            return s.removingPercentEncoding ?? s
        }

        return nil
    }

    private func handlePreviewHostEvent(_ event: WebHostEvent) {
        _ = event
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
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
                machine.startMarkdownExportFromEditor(runtime: editorRuntime, bookmarkLabel: bm.label)
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
}
