//
//  DocmarkDetailEvent.swift
//  YABACore
//

import Foundation

public enum DocmarkDetailEvent: Sendable {
    case onInit(bookmarkId: String)
    case onDeleteBookmark(bookmarkId: String)
    case onShareDocument
    case onExportDocument
    case onConsumePendingShare
    case onRequestNotificationPermission
    case onScheduleReminder(titleKey: String, messageKey: String, fireAt: Date)
    case onCancelReminder

    case updateDocMetadata(bookmarkId: String, summary: String?, type: DocmarkType?)

    case onSetEpubReaderTheme(ReaderTheme)
    case onSetEpubReaderFontSize(ReaderFontSize)
    case onSetEpubReaderLineHeight(ReaderLineHeight)
}
