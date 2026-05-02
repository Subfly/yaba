//
//  CanvmarkDetailStateMachine.swift
//  YABACore
//

import Foundation
import SwiftUI

@MainActor
public final class CanvmarkDetailStateMachine: YabaBaseObservableState<CanvmarkDetailUIState>, YabaScreenStateMachine {
    public override init(initialState: CanvmarkDetailUIState = CanvmarkDetailUIState()) {
        super.init(initialState: initialState)
    }

    public func send(_ event: CanvmarkDetailEvent) async {
        switch event {
        case let .onInit(bookmarkId):
            let reminderDate = await ReminderManager.getPendingReminderDate(bookmarkId: bookmarkId)
            apply {
                $0.bookmarkId = bookmarkId
                $0.reminderDate = reminderDate
            }
        case let .onSave(sceneJson):
            guard let bid = state.bookmarkId else { return }
            CanvmarkManager.queueSaveCanvasSceneData(bookmarkId: bid, sceneData: Data(sceneJson.utf8))
        case let .onWebInitialContentLoad(resultJson):
            apply { $0.webInitialContentLoadResultJson = resultJson }
        case .onPickImageFromGallery, .onCaptureImageFromCamera,
             .onConsumedPendingImageInsert:
            break
        case let .onCanvasMetricsChanged(metricsJson):
            apply { $0.metricsJson = metricsJson }
        case let .onCanvasStyleStateChanged(styleJson):
            apply { $0.styleJson = styleJson }
        case .onRequestNotificationPermission:
            _ = await ReminderManager.requestAuthorization()
            let granted = await ReminderManager.authorizationGranted()
            if !granted {
                CoreToastManager.shared.showNotificationPermissionDeniedToast()
            }
        case let .onDeleteBookmark(bookmarkId):
            AllBookmarksManager.queueDeleteBookmarks(bookmarkIds: [bookmarkId])
        case let .onDeleteCanvasInlineAsset(bid, assetId):
            CanvmarkManager.queueDeleteCanvasInlineAsset(bookmarkId: bid, assetId: assetId)
        case let .onScheduleReminder(titleKey, messageKey, fireAt):
            guard let bid = state.bookmarkId else { return }
            do {
                try await ReminderManager.scheduleReminderResolvingLabel(
                    bookmarkId: bid,
                    bookmarkKindCode: BookmarkKind.canvas.rawValue,
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
        case let .onExportImageReady(data, ext):
            apply {
                $0.pendingExportImageData = data
                $0.pendingExportImageExtension = ext
            }
        case let .saveScene(bookmarkId, sceneData):
            CanvmarkManager.queueSaveCanvasSceneData(bookmarkId: bookmarkId, sceneData: sceneData)
        }
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

    // MARK: - Canvas inline images (camera / gallery; scene bridge TBD)

    public func handlePickedInlineImage(
        data: Data,
        bookmarkId: String,
        storedPathExtension: String? = nil
    ) {
        let assetId = UUID().uuidString
        let rawExt = storedPathExtension ?? inferredInlineImagePathExtension(for: data)
        let ext = normalizedStoredInlineImageExtension(rawExt)
        CanvmarkManager.queueAppendCanvasInlineAsset(
            bookmarkId: bookmarkId,
            assetId: assetId,
            pathExtension: ext,
            bytes: data,
            completion: nil
        )
    }

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
