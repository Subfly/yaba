//
//  DocmarkDetailStateMachine.swift
//  YABACore
//

import Foundation
import SwiftUI

@MainActor
public final class DocmarkDetailStateMachine: YabaBaseObservableState<DocmarkDetailUIState>, YabaScreenStateMachine {
    public override init(initialState: DocmarkDetailUIState = DocmarkDetailUIState()) {
        super.init(initialState: initialState)
    }

    public func send(_ event: DocmarkDetailEvent) async {
        switch event {
        case let .onInit(bookmarkId):
            AllBookmarksManager.queueRecordBookmarkView(bookmarkId: bookmarkId)
            let reminderDate = await ReminderManager.getPendingReminderDate(bookmarkId: bookmarkId)
            apply {
                $0.bookmarkId = bookmarkId
                $0.reminderDate = reminderDate
            }
        case let .onDeleteBookmark(bookmarkId):
            AllBookmarksManager.queueDeleteBookmarks(bookmarkIds: [bookmarkId])
        case .onShareDocument:
            await handleShareDocument()
        case .onExportDocument:
            break
        case .onConsumePendingShare:
            if let url = state.pendingShareFileURL {
                try? FileManager.default.removeItem(at: url)
            }
            apply { $0.pendingShareFileURL = nil }
        case .onRequestNotificationPermission:
            _ = await ReminderManager.requestAuthorization()
            let granted = await ReminderManager.authorizationGranted()
            if !granted {
                CoreToastManager.shared.showNotificationPermissionDeniedToast()
            }
        case let .onScheduleReminder(titleKey, messageKey, fireAt):
            guard let bid = state.bookmarkId else { return }
            do {
                try await ReminderManager.scheduleReminderResolvingLabel(
                    bookmarkId: bid,
                    bookmarkKindCode: BookmarkKind.file.rawValue,
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
        case let .updateDocMetadata(bookmarkId, summary, type):
            DocmarkManager.queueCreateOrUpdateDocDetails(bookmarkId: bookmarkId, summary: summary, docmarkType: type)
        }
    }

    private func handleShareDocument() async {
        guard let bid = state.bookmarkId else { return }
        if let old = state.pendingShareFileURL {
            try? FileManager.default.removeItem(at: old)
        }
        apply { $0.pendingShareFileURL = nil }
        do {
            guard let payload = try await DocmarkManager.fetchExportPayload(bookmarkId: bid) else {
                CoreToastManager.shared.show(
                    message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                    iconType: .error,
                    duration: .short
                )
                return
            }
            let base = MarkdownExportSupport.sanitizeBaseFolderName(payload.label, emptyFallback: "document")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("YABA-\(base)-\(UUID().uuidString.prefix(8)).pdf", isDirectory: false)
            try payload.pdfData.write(to: url, options: .atomic)
            apply { $0.pendingShareFileURL = url }
        } catch {
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                iconType: .error,
                duration: .short
            )
        }
    }

    // MARK: - Save copy (directory picker)

    public func preparePdfSaveCopy(bookmarkLabel: String) {
        let base = MarkdownExportSupport.sanitizeBaseFolderName(bookmarkLabel, emptyFallback: "document")
        apply {
            $0.pdfSaveCopyFileBaseName = base
            $0.showPdfSaveCopyPicker = true
        }
    }

    public func finalizePdfSaveCopyDirectory(_ parentDirectory: URL?) {
        let baseName = state.pdfSaveCopyFileBaseName
        let bookmarkId = state.bookmarkId
        apply {
            $0.showPdfSaveCopyPicker = false
            $0.pdfSaveCopyFileBaseName = ""
        }
        guard let parentDirectory, !baseName.isEmpty, let bookmarkId else { return }
        Task {
            do {
                guard let payload = try await DocmarkManager.fetchExportPayload(bookmarkId: bookmarkId) else {
                    await MainActor.run {
                        CoreToastManager.shared.show(
                            message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                            iconType: .error,
                            duration: .short
                        )
                    }
                    return
                }
                let ok = await Task.detached {
                    MarkdownExportSupport.writePdf(data: payload.pdfData, into: parentDirectory, fileBaseName: baseName)
                }.value
                await MainActor.run {
                    if ok {
                        CoreToastManager.shared.show(
                            message: LocalizedStringKey("Export Successful Message"),
                            iconType: .success,
                            duration: .short
                        )
                    } else {
                        CoreToastManager.shared.show(
                            message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                            iconType: .error,
                            duration: .short
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    CoreToastManager.shared.show(
                        message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                        iconType: .error,
                        duration: .short
                    )
                }
            }
        }
    }

    public var showPdfSaveCopyPickerBinding: Binding<Bool> {
        Binding(
            get: { self.state.showPdfSaveCopyPicker },
            set: { newValue in self.apply { $0.showPdfSaveCopyPicker = newValue } }
        )
    }
}
