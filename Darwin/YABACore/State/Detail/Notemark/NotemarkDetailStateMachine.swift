//
//  NotemarkDetailStateMachine.swift
//  YABACore
//

import Foundation
import SwiftUI
import WebKit

@MainActor
public final class NotemarkDetailStateMachine: YabaBaseObservableState<NotemarkDetailUIState>, YabaScreenStateMachine {
    public override init(initialState: NotemarkDetailUIState = NotemarkDetailUIState()) {
        super.init(initialState: initialState)
    }

    /// Toolbar mode for SwiftUI animations (aliases ``NotemarkDetailUIState/surfaceMode``).
    public var selectedMode: NotemarkDetailSurfaceMode {
        state.surfaceMode
    }

    public func send(_ event: NotemarkDetailEvent) async {
        switch event {
        case let .onInit(bookmarkId):
            let reminderDate = await ReminderManager.getPendingReminderDate(bookmarkId: bookmarkId)
            apply {
                $0.bookmarkId = bookmarkId
                $0.reminderDate = reminderDate
            }
        case let .onSave(documentJson, _):
            guard let bid = state.bookmarkId else { return }
            let data = Data(documentJson.utf8)
            NotemarkManager.queueSaveNoteDocumentData(bookmarkId: bid, documentBody: data)
            ReadableContentManager.queueSyncNotemarkReadableMirror(bookmarkId: bid, html: documentJson)
            NotemarkManager.queueCreateOrUpdateNoteDetails(bookmarkId: bid)
        case let .onDeleteBookmark(bookmarkId):
            AllBookmarksManager.queueDeleteBookmarks(bookmarkIds: [bookmarkId])
        case .onRequestNotificationPermission:
            _ = await ReminderManager.requestAuthorization()
            let granted = await ReminderManager.authorizationGranted()
            if !granted {
                CoreToastManager.shared.showNotificationPermissionDeniedToast()
            }
        case .onPickImageFromGallery, .onCaptureImageFromCamera:
            break
        case let .onWebInitialContentLoad(resultJson):
            apply { $0.webInitialContentLoadResultJson = resultJson }
        case .onConsumedInlineImageInsert:
            apply { $0.inlineImageDocumentSrc = nil }
        case let .onScheduleReminder(titleKey, messageKey, fireAt):
            guard let bid = state.bookmarkId else { return }
            do {
                try await ReminderManager.scheduleReminderResolvingLabel(
                    bookmarkId: bid,
                    bookmarkKindCode: BookmarkKind.note.rawValue,
                    titleKey: titleKey,
                    messageKey: messageKey,
                    fireAt: fireAt
                )
                apply { $0.reminderDate = fireAt }
                CoreToastManager.shared.showReminderScheduledToast(fireAt: fireAt)
            } catch {
                CoreToastManager.shared.showReminderScheduleFailedToast()
            }
        case .onCancelReminder:
            guard let bid = state.bookmarkId else { return }
            ReminderManager.cancelReminder(bookmarkId: bid)
            apply { $0.reminderDate = nil }
        case let .onExportMarkdownReady(md):
            apply { $0.lastExportMarkdown = md }
        case let .onExportPdfReady(b64):
            apply { $0.lastExportPdfBase64 = b64 }
        case let .saveDocument(bookmarkId, data):
            NotemarkManager.queueSaveNoteDocumentData(bookmarkId: bookmarkId, documentBody: data)
        case let .ensureReadableMirror(bookmarkId, json):
            ReadableContentManager.queueSyncNotemarkReadableMirror(
                bookmarkId: bookmarkId,
                html: json
            )
        case let .onDeleteNoteInlineAsset(bookmarkId, assetId):
            NotemarkManager.queueDeleteNoteInlineAsset(bookmarkId: bookmarkId, assetId: assetId)
        }
    }

    // MARK: - Note inline images (camera / gallery)

    /// Persists bytes on the note bookmark, then yields editor bridge JSON to insert `![](yaba-asset://…)`.
    /// Pass `storedPathExtension` when the source already implies a type (e.g. camera JPEG); otherwise it is inferred from `data` (gallery).
    public func handlePickedInlineImage(
        data: Data,
        bookmarkId: String,
        storedPathExtension: String? = nil,
        onAssetPersisted: @escaping @MainActor (String) -> Void
    ) {
        let assetId = UUID().uuidString
        let rawExt = storedPathExtension ?? inferredInlineImagePathExtension(for: data)
        let ext = normalizedStoredInlineImageExtension(rawExt)
        NotemarkManager.queueAppendNoteInlineAsset(
            bookmarkId: bookmarkId,
            assetId: assetId,
            pathExtension: ext,
            bytes: data
        ) { error in
            guard error == nil else { return }
            let insert = YabaEditorDispatchPayload.insertLink(
                text: "",
                url: "yaba-asset://\(assetId)",
                asImage: true
            )
            Task { @MainActor in
                onAssetPersisted(insert)
            }
        }
    }

    // MARK: - Editor snapshot (WKWebView bridge)

    public func persistEditorSnapshot(runtime: WKWebViewRuntime) async {
        guard let md = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.getMarkdown()) else {
            return
        }
        let srcsJson = (try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.getUsedInlineAssetSrcs())) ?? "[]"
        let srcs = Self.parseInlineAssetSrcJson(srcsJson)
        await send(.onSave(documentJson: md, usedInlineAssetSrcs: srcs))
    }

    public func startMarkdownExportFromEditor(runtime: WKWebViewRuntime?, bookmarkLabel: String) {
        guard let runtime else {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
            return
        }
        Task {
            let md = (try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.exportMarkdown())) ?? ""
            await MainActor.run {
                self.startMarkdownExport(markdown: md, bookmarkLabel: bookmarkLabel, inlineSources: [])
            }
        }
    }

    public func preparePdfExportIfEditorHasBody(
        runtime: WKWebViewRuntime?,
        persistedMarkdown: String,
        bookmarkLabel: String
    ) {
        Task {
            let trimmed: String
            if let runtime,
               let md = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.getMarkdown())
            {
                trimmed = md.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                trimmed = persistedMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            await MainActor.run {
                guard !trimmed.isEmpty else {
                    CoreToastManager.shared.show(
                        message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                        iconType: .error,
                        duration: .short
                    )
                    return
                }
                self.preparePdfExport(bookmarkLabel: bookmarkLabel)
            }
        }
    }

    private static func parseInlineAssetSrcJson(_ json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [String]
        else {
            return []
        }
        return arr
    }

    // MARK: - Sheet & alert bindings (SwiftUI)

    public var showDetailSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showDetailSheet },
            set: { newValue in self.apply { $0.showDetailSheet = newValue } }
        )
    }

    public var showEditSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showEditSheet },
            set: { newValue in self.apply { $0.showEditSheet = newValue } }
        )
    }

    public var showMoveSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showMoveSheet },
            set: { newValue in self.apply { $0.showMoveSheet = newValue } }
        )
    }

    public var showReminderSheetBinding: Binding<Bool> {
        Binding(
            get: { self.state.showReminderSheet },
            set: { newValue in self.apply { $0.showReminderSheet = newValue } }
        )
    }

    public var showDeleteAlertBinding: Binding<Bool> {
        Binding(
            get: { self.state.showDeleteAlert },
            set: { newValue in self.apply { $0.showDeleteAlert = newValue } }
        )
    }

    public var showMarkdownExportDirectoryPickerBinding: Binding<Bool> {
        Binding(
            get: { self.state.showMarkdownExportDirectoryPicker },
            set: { newValue in self.apply { $0.showMarkdownExportDirectoryPicker = newValue } }
        )
    }

    public var showPdfExportDirectoryPickerBinding: Binding<Bool> {
        Binding(
            get: { self.state.showPdfExportDirectoryPicker },
            set: { newValue in self.apply { $0.showPdfExportDirectoryPicker = newValue } }
        )
    }

    public var editorPdfExportBinding: Binding<LinkmarkReaderPdfExport?> {
        Binding(
            get: { self.state.editorPdfExport },
            set: { newValue in self.apply { $0.editorPdfExport = newValue } }
        )
    }

    // MARK: - Markdown export

    public func startMarkdownExport(
        markdown: String,
        bookmarkLabel: String,
        inlineSources: [MarkdownExportInlineSource]
    ) {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
            return
        }
        let request = MarkdownExportRequest(
            markdown: trimmed + "\n",
            baseFolderName: ExportSupport.sanitizeBaseFolderName(bookmarkLabel),
            assets: ExportSupport.exportAssets(from: inlineSources)
        )
        apply {
            $0.markdownExportRequest = request
            $0.showMarkdownExportDirectoryPicker = true
        }
    }

    public func finalizeMarkdownExport(selectedDirectory: URL?) {
        let request = state.markdownExportRequest
        apply { $0.markdownExportRequest = nil }
        guard let selectedDirectory, let request else { return }
        let didWrite = ExportSupport.writeBundle(request, into: selectedDirectory)
        if !didWrite {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
        }
    }

    // MARK: - Editor PDF export (directory picker + WKWebView.createPDF)

    public func preparePdfExport(bookmarkLabel: String) {
        let base = ExportSupport.sanitizeBaseFolderName(bookmarkLabel, emptyFallback: "note")
        apply {
            $0.pdfExportFileBaseName = base
            $0.showPdfExportDirectoryPicker = true
        }
    }

    public func finalizePdfExportDirectorySelection(_ parentDirectory: URL?) {
        let baseName = state.pdfExportFileBaseName
        apply {
            $0.showPdfExportDirectoryPicker = false
            $0.pdfExportFileBaseName = ""
            if let parentDirectory, !baseName.isEmpty {
                $0.editorPdfExport = LinkmarkReaderPdfExport(parentDirectory: parentDirectory, fileBaseName: baseName)
            } else {
                $0.editorPdfExport = nil
            }
        }
    }
    
    /// Sniff JPEG / PNG / WebP from magic bytes; default `jpg`.
    private func inferredInlineImagePathExtension(for data: Data) -> String {
        guard !data.isEmpty else { return "jpg" }
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

    private func normalizedStoredInlineImageExtension(_ raw: String) -> String {
        let t = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        if t == "jpeg" { return "jpg" }
        return t.isEmpty ? "jpg" : t
    }
}
