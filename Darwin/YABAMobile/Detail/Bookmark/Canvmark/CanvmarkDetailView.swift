//
//  CanvmarkDetailView.swift
//  YABA
//

import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import WebKit

/// Canvas bookmark detail — Excalidraw web shell + chrome (toolbar, overflow, info sheet).
struct CanvmarkDetailView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void
    let onOpenBookmark: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.openURL)
    private var openURL

    @Query
    private var bookmarks: [YabaBookmark]

    @State
    private var machine = CanvmarkDetailStateMachine()

    @State
    private var reminderDraft = Date().addingTimeInterval(3600)

    @State
    private var showAddLinkSheet = false

    @State
    private var addLinkSheetMode: AddLinkSheetMode = .link

    @State
    private var showAddMentionSheet = false

    @State
    private var galleryPhotoItem: PhotosPickerItem?

    @State
    private var showCameraCapture = false

    @State
    private var canvasRuntime: WKWebViewRuntime?

    @State
    private var presentExportShareSheet = false

    init(
        bookmarkId: String,
        onOpenFolder: @escaping (String) -> Void = { _ in },
        onOpenTag: @escaping (String) -> Void = { _ in },
        onOpenBookmark: @escaping (String) -> Void = { _ in }
    ) {
        self.bookmarkId = bookmarkId
        self.onOpenFolder = onOpenFolder
        self.onOpenTag = onOpenTag
        self.onOpenBookmark = onOpenBookmark
        var d = FetchDescriptor<YabaBookmark>(
            predicate: #Predicate<YabaBookmark> { $0.bookmarkId == bookmarkId }
        )
        d.fetchLimit = 1
        _bookmarks = Query(d, animation: .smooth)
    }

    var body: some View {
        Group {
            if let bm = bookmark {
                if bm.kind == .canvas {
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
                CanvmarkDetailInfoSheet(
                    bookmark: bm,
                    folderAccent: folderColor(for: bm),
                    reminderDate: machine.state.reminderDate,
                    onDeleteReminder: {
                        Task { await machine.send(.onCancelReminder) }
                    },
                    onDeleteAsset: { assetId in
                        Task { await machine.send(.onDeleteCanvasInlineAsset(bookmarkId: bm.bookmarkId, assetId: assetId)) }
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
                            machine.apply { $0.showMoveSheet = false }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: machine.showReminderSheetBinding) {
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
                        Button("Cancel") { machine.apply { $0.showReminderSheet = false } }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
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
                    }
                }
            }
        }
        .sheet(isPresented: $showAddLinkSheet) {
            NavigationStack {
                AddLinkSheet(mode: addLinkSheetMode) { text, url in
                    let payload = CanvasInlineApplyJsonDarwin.insertTextWithUrl(
                        displayText: text.trimmingCharacters(in: .whitespacesAndNewlines),
                        url: url.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    canvasApplyInlinePayload(payloadJson: payload)
                    showAddLinkSheet = false
                }
            }
        }
        .sheet(isPresented: $showAddMentionSheet) {
            NavigationStack {
                AddMentionSheet(excludeBookmarkId: bookmarkId) { displayText, mentionURL in
                    let trimmedDisplay = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let mentionedId = bookmarkId(fromYabaMentionURL: mentionURL) else {
                        showAddMentionSheet = false
                        return
                    }
                    let json = canvmarkMentionInsertJson(displayText: trimmedDisplay, mentionedBookmarkId: mentionedId)
                        ?? CanvasInlineApplyJsonDarwin.insertTextWithMention(
                            displayText: trimmedDisplay,
                            bookmarkId: mentionedId,
                            bookmarkKindCode: 0,
                            bookmarkLabel: ""
                        )
                    canvasApplyInlinePayload(payloadJson: json)
                    showAddMentionSheet = false
                }
            }
        }
        .sheet(isPresented: $presentExportShareSheet, onDismiss: {
            machine.apply {
                $0.pendingExportImageData = nil
            }
        }) {
            if let data = machine.state.pendingExportImageData {
                ActivityItemsShareSheet(items: shareItemsForExportedCanvas(data: data, ext: machine.state.pendingExportImageExtension))
            }
        }
        .fullScreenCover(isPresented: $showCameraCapture) {
            CameraCapturePicker(
                onDismiss: { showCameraCapture = false },
                onCapture: { data in
                    showCameraCapture = false
                    machine.handlePickedInlineImage(data: data, bookmarkId: bookmarkId, storedPathExtension: "jpg")
                    insertCanvasRasterFromData(data, storedExtension: "jpg")
                }
            )
            .ignoresSafeArea()
        }
        .alert("Delete Bookmark Title", isPresented: machine.showDeleteAlertBinding) {
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

    private func folderColor(for bm: YabaBookmark) -> Color {
        bm.folder?.color.getUIColor() ?? .accentColor
    }

    private func folderCursorCss(for bm: YabaBookmark) -> String? {
        bm.folder?.color.canonicalHexDigits.map { "#\($0)" }
    }

    private func canvmarkStoredSceneJson(for bm: YabaBookmark) -> String {
        guard let data = bm.canvasDetail?.payload?.sceneData, !data.isEmpty else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func canvmarkInlineAssets(for bm: YabaBookmark) -> [YabaInlineAssetPayload] {
        (bm.canvasDetail?.inlineAssets ?? []).compactMap { YabaInlineAssetPayload(inlineAsset: $0) }
    }

    @MainActor
    private func persistCanvasSceneIfPossible() async {
        guard let rt = canvasRuntime else { return }
        do {
            let json = try await rt.canvasSnapshotSceneJson()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !json.isEmpty else { return }
            await machine.send(.onSave(sceneJson: json))
        } catch {}
    }

    private func canvmarkEncode<T: Encodable>(_ value: T) -> String? {
        guard let d = try? JSONEncoder().encode(value) else { return nil }
        return String(data: d, encoding: .utf8)
    }

    private func handleCanvasHostEvent(_ event: WebHostEvent) {
        switch event {
        case let .initialContentLoad(result):
            let resultJson = (result == .loaded)
                ? #"{"result":"loaded"}"#
                : #"{"result":"error"}"#
            Task {
                await machine.send(.onWebInitialContentLoad(resultJson: resultJson))
            }

        case .canvasIdleForAutosave:
            Task { await persistCanvasSceneIfPossible() }

        case let .canvasMetrics(metrics):
            if let encoded = canvmarkEncode(metrics) {
                Task {
                    await machine.send(.onCanvasMetricsChanged(metricsJson: encoded))
                }
            }

        case let .canvasStyleState(style):
            if let encoded = canvmarkEncode(style) {
                Task {
                    await machine.send(.onCanvasStyleStateChanged(styleJson: encoded))
                }
            }

        case let .canvasLinkTap(_, _, url):
            if let u = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)),
               ["http", "https"].contains(u.scheme?.lowercased()) {
                openURL(u)
            }

        case let .canvasMentionTap(_, _, mentionedId, _, _):
            guard !mentionedId.isEmpty else { return }
            onOpenBookmark(mentionedId)

        default:
            break
        }
    }

    private func canvasToolbar(tool: CanvmarkEditorFloatingToolbar.CanvmarkToolbarTool) {
        guard let rt = canvasRuntime else { return }
        Task {
            guard let token = tool.canvasBridgeActiveToolToken else { return }
            try? await rt.canvasSetActiveTool(token)
        }
    }

    private func canvasRedo() {
        guard let rt = canvasRuntime else { return }
        Task { try? await rt.canvasRedo() }
    }

    private func canvasUndo() {
        guard let rt = canvasRuntime else { return }
        Task { try? await rt.canvasUndo() }
    }

    private func canvasApplyInlinePayload(payloadJson: String) {
        guard let rt = canvasRuntime else { return }
        Task { try? await rt.canvasApplyInline(payloadJson: payloadJson) }
    }

    private func bookmarkId(fromYabaMentionURL raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = "yaba-mention://"
        guard trimmed.lowercased().hasPrefix(prefix.lowercased()) else { return nil }
        let id = String(trimmed.dropFirst(prefix.count))
        let trimmedId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedId.isEmpty ? nil : trimmedId
    }

    private func canvmarkMentionInsertJson(displayText: String, mentionedBookmarkId: String) -> String? {
        guard let ref = BookmarkFlowHydration.fetchBookmark(bookmarkId: mentionedBookmarkId) else { return nil }
        return CanvasInlineApplyJsonDarwin.insertTextWithMention(
            displayText: displayText,
            bookmarkId: mentionedBookmarkId,
            bookmarkKindCode: ref.kind.rawValue,
            bookmarkLabel: ref.label
        )
    }

    private func shareItemsForExportedCanvas(data: Data, ext: String) -> [Any] {
        let trimmed = ext.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed {
        case "svg":
            if let s = String(data: data, encoding: .utf8) {
                let temp = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("yaba-canvas-export-\(UUID().uuidString).svg")
                try? s.write(to: temp, atomically: true, encoding: .utf8)
                return [temp]
            }
            return []
        default:
            if let image = UIImage(data: data) {
                return [image]
            }
            return []
        }
    }

    private func mimeType(forStoredRasterExtension raw: String) -> String {
        let e = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        switch e {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return "image/jpeg"
        }
    }

    private func insertCanvasRasterFromData(_ data: Data, storedExtension rawExt: String) {
        guard !data.isEmpty else { return }
        let mime = mimeType(forStoredRasterExtension: rawExt)
        let b64 = data.base64EncodedString()
        let url = "data:\(mime);base64,\(b64)"
        guard let rt = canvasRuntime else { return }
        Task { try? await rt.canvasInsertImage(dataUrl: url) }
    }

    private func inferredRasterExtension(for data: Data) -> String {
        guard data.count >= 4 else { return "jpg" }
        let b = [UInt8](data.prefix(12))
        if b.count >= 3, b[0] == 0xFF, b[1] == 0xD8 { return "jpg" }
        if b.count >= 8, b[0] == 0x89, b[1] == 0x50, b[2] == 0x4E, b[3] == 0x47 { return "png" }
        if b.count >= 12,
           b[0] == 0x52, b[1] == 0x49, b[2] == 0x46, b[3] == 0x46,
           b[8] == 0x57, b[9] == 0x45, b[10] == 0x42, b[11] == 0x50
        {
            return "webp"
        }
        return "jpg"
    }

    @MainActor
    private func exportCanvas(format: String) async {
        guard let rt = canvasRuntime else {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
            return
        }
        let bg = machine.state.exportIncludeBackground
        guard let data = await rt.canvasExportImageData(format: format, exportBackground: bg),
              !data.isEmpty
        else {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
            return
        }
        let ext = format.lowercased() == "svg" ? "svg" : "png"
        await machine.send(.onExportImageReady(data, fileExtension: ext))
        presentExportShareSheet = true
    }

    @ViewBuilder
    private func mainContent(for bm: YabaBookmark) -> some View {
        let folderTint = folderColor(for: bm)
        ZStack(alignment: .bottom) {
            Color(.systemBackground)
                .ignoresSafeArea()

            CanvmarkEditorWebView(
                bookmarkId: bm.bookmarkId,
                initialSceneJson: canvmarkStoredSceneJson(for: bm),
                inlineAssets: canvmarkInlineAssets(for: bm),
                appearance: .auto,
                folderCursorCss: folderCursorCss(for: bm),
                onHostEvent: handleCanvasHostEvent,
                onRuntimeReady: { rt in
                    canvasRuntime = rt
                }
            )
            .ignoresSafeArea(edges: .all)

            HStack {
                Spacer(minLength: 0)
                CanvmarkEditorFloatingToolbar(
                    folderAccent: folderTint,
                    isVisible: true,
                    onTool: { canvasToolbar(tool: $0) },
                    onRequestAddLinkSheet: { mode in
                        addLinkSheetMode = mode
                        showAddLinkSheet = true
                    },
                    onRequestAddMentionSheet: {
                        showAddMentionSheet = true
                    },
                    onRequestPickImageFromCamera: {
                        showCameraCapture = true
                    },
                    galleryPhotoItem: $galleryPhotoItem,
                    onUndo: { canvasUndo() },
                    onRedo: { canvasRedo() }
                )
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)
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
                    machine.apply { $0.showDetailSheet = true }
                } label: {
                    homeToolbarIcon("information-circle")
                }
            }
            if #available(iOS 26, *) {
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                overflowMenu(for: bm)
            }
        }
        .tint(folderTint)
        .onChange(of: galleryPhotoItem) { _, new in
            Task {
                guard let new else { return }
                let bid = bm.bookmarkId
                guard let data = try? await new.loadTransferable(type: Data.self) else {
                    await MainActor.run { galleryPhotoItem = nil }
                    return
                }
                let ext = inferredRasterExtension(for: data)
                await MainActor.run {
                    machine.handlePickedInlineImage(data: data, bookmarkId: bid, storedPathExtension: ext)
                    galleryPhotoItem = nil
                }
                await MainActor.run {
                    insertCanvasRasterFromData(data, storedExtension: ext)
                }
            }
        }
        .onDisappear {
            Task { await persistCanvasSceneIfPossible() }
        }
    }

    @ViewBuilder
    private func overflowMenu(for bm: YabaBookmark) -> some View {
        Menu {
            Button {
                machine.apply { $0.showEditSheet = true }
            } label: {
                overflowMenuItemLabel("Edit", icon: "edit-02")
            }
            .tint(YabaColor.orange.getUIColor())
            Button {
                machine.apply { $0.showMoveSheet = true }
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
                    Task { await exportCanvas(format: "png") }
                } label: {
                    overflowMenuItemLabel("Canvmark Option Export PNG Action Label", icon: "png-02")
                }
                .tint(YabaColor.gray.getUIColor())
                Button {
                    Task { await exportCanvas(format: "svg") }
                } label: {
                    overflowMenuItemLabel("Canvmark Option Export SVG Action Label", icon: "svg-02")
                }
                .tint(YabaColor.yellow.getUIColor())
                Divider()
                Toggle(isOn: exportIncludeBackgroundBinding()) {
                    Text("Canvmark Option Export Background Action Label")
                }
                .menuActionDismissBehavior(.disabled)
                .tint(folderColor(for: bm))
            } label: {
                overflowMenuItemLabel("Canvmark Option Export Action Label", icon: "download-01")
            }
            .tint(YabaColor.blue.getUIColor())
            if machine.state.reminderDate == nil {
                Button {
                    machine.apply { $0.showReminderSheet = true }
                } label: {
                    overflowMenuItemLabel("Remind Me", icon: "notification-01")
                }
                .tint(YabaColor.yellow.getUIColor())
            }
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
                machine.apply { $0.showDeleteAlert = true }
            } label: {
                overflowMenuItemLabel("Delete", icon: "delete-02")
            }
            .tint(YabaColor.red.getUIColor())
        } label: {
            homeToolbarIcon("more-horizontal-circle-02")
        }
    }

    private func exportIncludeBackgroundBinding() -> Binding<Bool> {
        Binding(
            get: { machine.state.exportIncludeBackground },
            set: { newValue in machine.apply { $0.exportIncludeBackground = newValue } }
        )
    }

    @ViewBuilder
    private func homeToolbarIcon(_ bundleKey: String) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .frame(width: 22, height: 22)
    }

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
}
