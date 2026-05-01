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
    case onToggleReaderTheme
    case onToggleReaderFontSize
    case onToggleReaderLineHeight
    case onSetReaderTheme(ReaderTheme)
    case onSetReaderFontSize(ReaderFontSize)
    case onSetReaderLineHeight(ReaderLineHeight)
    case onRequestNotificationPermission
    case onScheduleReminder(titleKey: String, messageKey: String, fireAt: Date)
    case onCancelReminder
    case onWebInitialContentLoad(resultJson: String?)

    case updateDocMetadata(bookmarkId: String, summary: String?, type: DocmarkType?)
}
