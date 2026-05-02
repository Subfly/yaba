//
//  CanvmarkDetailEvent.swift
//  YABACore
//

import Foundation

public enum CanvmarkDetailEvent: Sendable {
    case onInit(bookmarkId: String)
    case onSave(sceneJson: String)
    case onWebInitialContentLoad(resultJson: String?)
    case onCanvasMetricsChanged(metricsJson: String?)
    case onCanvasStyleStateChanged(styleJson: String?)
    case onPickImageFromGallery
    case onCaptureImageFromCamera
    case onConsumedPendingImageInsert
    case onDeleteBookmark(bookmarkId: String)
    case onDeleteCanvasInlineAsset(bookmarkId: String, assetId: String)
    case onRequestNotificationPermission
    case onScheduleReminder(titleKey: String, messageKey: String, fireAt: Date)
    case onCancelReminder
    case onExportImageReady(Data, fileExtension: String)
    case saveScene(bookmarkId: String, sceneData: Data)
}
