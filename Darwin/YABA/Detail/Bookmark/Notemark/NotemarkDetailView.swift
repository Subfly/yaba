//
//  NotemarkDetailView.swift
//  YABA
//

import SwiftData
import SwiftUI
import WebKit
import PhotosUI

/// SwiftData-driven note bookmark detail + unified `note.html` editor/preview host.
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
    private var noteRuntime: WKWebViewRuntime?
    
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
    
    @State
    private var showNotemarkNavGalleryPhotoPicker = false
    
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
                        dispatchNoteCommand(YabaEditorDispatchPayload.insertLink(text: text, url: url))
                    case .image:
                        dispatchNoteCommand(YabaEditorDispatchPayload.insertLink(text: text, url: url, asImage: true))
                    }
                    showAddLinkSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddTableSheet) {
            NavigationStack {
                AddTableSheet { rows, cols in
                    dispatchNoteCommand(YabaEditorDispatchPayload.insertTable(rows: rows, cols: cols, withHeaderRow: false))
                    showAddTableSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddMentionSheet) {
            NavigationStack {
                AddMentionSheet(excludeBookmarkId: bookmarkId) { text, url in
                    dispatchNoteCommand(YabaEditorDispatchPayload.insertLink(text: text, url: url))
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
                        onAssetPersisted: { dispatchNoteCommand($0) }
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
    
    /// Floating bottom chrome is iPhone-only; iPad and Mac Catalyst use the navigation toolbar title area.
    private var usesFloatingNotemarkEditorToolbar: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    private var notemarkEditorChromeVisible: Bool {
        machine.state.surfaceMode == .editor || machine.state.surfaceMode == .split
    }
    
    private var notemarkEditorShowsDoneButton: Bool {
        notemarkEditorChromeVisible && isSoftwareKeyboardVisible
    }
    
    private var notemarkSurfaceModeToolbarIconKey: String {
        switch machine.state.surfaceMode {
        case .editor:
            return "edit-01"
        case .preview:
            return "book-open-01"
        case .split:
            return "column-insert"
        }
    }
    
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
            
            NotemarkNoteWebView(
                markdown: markdown,
                inlineAssets: notemarkPreviewInlineAssets(for: bm),
                readerPreferences: readerPreferences,
                appearance: .auto,
                surfaceMode: machine.state.surfaceMode,
                onHostEvent: { event in
                    handleNoteHostEvent(event)
                },
                onPersistDocument: { runtime in
                    await machine.persistEditorSnapshot(runtime: runtime)
                },
                onRuntimeReady: { runtime in
                    noteRuntime = runtime
                },
                onHighlightColorMarkTap: { ev in
                    previewHighlightMarkEdit = nil
                    highlightColorPick = YabaColor.fromPaletteHexDigits(ev.hexDigits) ?? .blue
                    highlightColorMarkEdit = ev
                    showHighlightColorSheet = true
                },
                onInlineLinkTap: handlePreviewInlineLinkTap,
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
                        await handlePreviewTaskCheckboxTapInWeb(bracketOpen: ev.bracketOpen)
                    }
                }
            )
            .id(bm.bookmarkId)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: [.top, .bottom])
            .preferredColorScheme(
                BookmarkDetailReaderChrome.preferredColorScheme(
                    readerTheme: machine.state.readerTheme,
                    userInterfaceColorScheme: colorScheme
                )
            )
            
            if usesFloatingNotemarkEditorToolbar {
                HStack {
                    Spacer(minLength: 0)
                    NotemarkEditorFloatingToolbar(
                        folderAccent: folderTint,
                        isVisible: notemarkEditorChromeVisible,
                        showsDoneButton: notemarkEditorShowsDoneButton,
                        onDispatch: { payload in
                            dispatchNoteCommand(payload)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if UIDevice.current.userInterfaceIdiom != .pad, machine.state.surfaceMode == .split {
                machine.apply { $0.surfaceMode = .editor }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            guard machine.state.surfaceMode == .editor || machine.state.surfaceMode == .split else { return }
            isSoftwareKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isSoftwareKeyboardVisible = false
        }
        .onChange(of: machine.state.surfaceMode) { _, newMode in
            if newMode == .preview {
                isSoftwareKeyboardVisible = false
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsBackButton {
                BookmarkDetailPrimaryToolbarPieces.backDismissButton { dismiss() }
            }
            if !usesFloatingNotemarkEditorToolbar, notemarkEditorChromeVisible {
                NotemarkEditorNavigationTitleToolbar.items(
                    folderAccent: folderTint,
                    showsDoneButton: notemarkEditorShowsDoneButton,
                    showGalleryPhotoPicker: $showNotemarkNavGalleryPhotoPicker,
                    galleryPhotoItem: $notemarkGalleryPhotoItem,
                    onDispatch: { payload in
                        dispatchNoteCommand(payload)
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
                    }
                )
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    notemarkSurfaceModeToggleTapped()
                } label: {
                    BookmarkDetailHomeToolbarGlyph(
                        bundleKey: notemarkSurfaceModeToolbarIconKey
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
                        onAssetPersisted: { dispatchNoteCommand($0) }
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
    
    private func handleNoteHostEvent(_ event: WebHostEvent) {
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
    
    private func notemarkSurfaceModeToggleTapped() {
        Task { @MainActor in
            await performNotemarkSurfaceModeAdvance()
        }
    }
    
    @MainActor
    private func performNotemarkSurfaceModeAdvance() async {
        let current = machine.state.surfaceMode
        let next = advanceNotemarkSurfaceMode(from: current)
        
        if current == .editor, next == .preview {
            await resignNotemarkEditorFirstResponder()
        }
        
        withAnimation(.smooth) {
            machine.apply { $0.surfaceMode = next }
        }
    }
    
    private func advanceNotemarkSurfaceMode(from current: NotemarkDetailSurfaceMode) -> NotemarkDetailSurfaceMode {
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch current {
            case .editor:
                return .preview
            case .preview:
                return .split
            case .split:
                return .editor
            }
        } else {
            switch current {
            case .editor:
                return .preview
            case .preview:
                return .editor
            case .split:
                return .editor
            }
        }
    }
    
    private func dispatchNoteCommand(_ payload: String) {
        Task { @MainActor in
            guard let rt = noteRuntime else { return }
            _ = try? await rt.evaluateJavaScriptStringResult(WebNoteBridgeScripts.dispatchCommand(payload))
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
                guard let rt = noteRuntime else { return }
                _ = try? await rt.evaluateJavaScriptStringResult(
                    WebNoteBridgeScripts.replacePreviewHighlightSyntax(
                        syntaxStart: previewEv.syntaxStart,
                        syntaxEnd: previewEv.syntaxEnd,
                        innerStart: previewEv.innerStart,
                        innerEnd: previewEv.innerEnd,
                        hexDigits: hex
                    )
                )
            }
            return
        }
        
        guard let editorEv else { return }
        Task { @MainActor in
            guard let rt = noteRuntime else { return }
            _ = try? await rt.evaluateJavaScriptStringResult(
                WebNoteBridgeScripts.replaceHighlightColorMark(
                    from: editorEv.from,
                    to: editorEv.to,
                    hexDigits: hex
                )
            )
        }
    }
    
    @MainActor
    private func handlePreviewTaskCheckboxTapInWeb(bracketOpen: Int) async {
        guard let rt = noteRuntime else { return }
        _ = try? await rt.evaluateJavaScriptStringResult(
            WebNoteBridgeScripts.togglePreviewTaskCheckbox(bracketOpen: bracketOpen)
        )
    }
    
    @MainActor
    private func resignNotemarkEditorFirstResponder() async {
        if let rt = noteRuntime {
            _ = try? await rt.evaluateJavaScriptStringResult(WebNoteBridgeScripts.unFocus())
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
                machine.startMarkdownExportFromEditor(runtime: noteRuntime, bookmarkLabel: bm.label)
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
