//
//  MediamarkDetailEvent.swift
//  YABACore
//

import Foundation

public enum MediamarkDetailEvent: Sendable {
    case onInit(bookmarkId: String)
    case onDeleteBookmark(bookmarkId: String)
    case onShareImage
    case onExportImage
    case onConsumePendingShare
    case onRequestNotificationPermission
    case onScheduleReminder(titleKey: String, messageKey: String, fireAt: Date)
    case onCancelReminder
}
