//
//  MediamarkDetailStateMachine.swift
//  YABACore
//

import Foundation
import Photos
import SwiftUI

@MainActor
public final class MediamarkDetailStateMachine: YabaBaseObservableState<MediamarkDetailUIState>, YabaScreenStateMachine {
    public override init(initialState: MediamarkDetailUIState = MediamarkDetailUIState()) {
        super.init(initialState: initialState)
    }

    public func send(_ event: MediamarkDetailEvent) async {
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
        case .onShareMedia:
            await handleShareMedia()
        case .onExportMedia:
            await handleExportMedia()
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
                    bookmarkKindCode: BookmarkKind.media.rawValue,
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
        }
    }

    private func handleShareMedia() async {
        guard let bid = state.bookmarkId else { return }
        if let old = state.pendingShareFileURL {
            try? FileManager.default.removeItem(at: old)
        }
        apply { $0.pendingShareFileURL = nil }
        do {
            guard let payload = try await MediamarkManager.fetchExportPayload(bookmarkId: bid) else {
                CoreToastManager.shared.show(
                    message: "Bookmark Detail Image Error Title",
                    iconType: .error,
                    duration: .short
                )
                return
            }
            let fallback: String
            switch payload.mediaMarkType {
            case .image:
                fallback = "image"
            case .video:
                fallback = "video"
            case .audio:
                fallback = "audio"
            }
            let base = MarkdownExportSupport.sanitizeBaseFolderName(payload.label, emptyFallback: fallback)
            let ext = payload.fileExtension
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("YABA-\(base)-\(UUID().uuidString.prefix(8)).\(ext)")
            try payload.mediaData.write(to: url, options: .atomic)
            apply { $0.pendingShareFileURL = url }
        } catch {
            CoreToastManager.shared.show(
                message: LocalizedStringKey(""),
                iconType: .error,
                duration: .short
            )
        }
    }

    private func handleExportMedia() async {
        guard let bid = state.bookmarkId else { return }
        do {
            guard let payload = try await MediamarkManager.fetchExportPayload(bookmarkId: bid) else {
                CoreToastManager.shared.show(
                    message: "Bookmark Detail Image Error Title",
                    iconType: .error,
                    duration: .short
                )
                return
            }
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                CoreToastManager.shared.showNotificationPermissionDeniedToast()
                return
            }
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "YABA-export-photos-\(UUID().uuidString).\(payload.fileExtension)",
                    isDirectory: false
                )
            try payload.mediaData.write(to: fileURL, options: .atomic)
            defer { try? FileManager.default.removeItem(at: fileURL) }
            var creationRequestFailed = false
            try await PHPhotoLibrary.shared().performChanges {
                switch payload.mediaMarkType {
                case .image:
                    if PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL) == nil {
                        creationRequestFailed = true
                    }
                case .video:
                    if PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL) == nil {
                        creationRequestFailed = true
                    }
                case .audio:
                    creationRequestFailed = true
                }
            }
            if creationRequestFailed {
                CoreToastManager.shared.show(
                    message: "Bookmark Detail Image Error Title",
                    iconType: .error,
                    duration: .short
                )
                return
            }
            CoreToastManager.shared.show(
                message: LocalizedStringKey("Bookmark Detail Saved to Photos Message"),
                iconType: .success,
                duration: .short
            )
        } catch {
            CoreToastManager.shared.show(
                message: "",
                iconType: .error,
                duration: .short
            )
        }
    }
}
