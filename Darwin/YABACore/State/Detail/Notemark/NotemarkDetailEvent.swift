//
//  NotemarkDetailEvent.swift
//  YABACore
//

import Foundation

public enum NotemarkDetailEvent: Sendable {
    case onInit(bookmarkId: String)
    case onSave(document: String, usedInlineAssetSrcs: [String])
    case onDeleteBookmark(bookmarkId: String)
    case onRequestNotificationPermission
    case onScheduleReminder(titleKey: String, messageKey: String, fireAt: Date)
    case onCancelReminder
    case onPickImageFromGallery
    case onCaptureImageFromCamera
    case onConsumedInlineImageInsert
    case onWebInitialContentLoad(result: String?)
    case onExportMarkdownReady(String)

    case saveDocument(bookmarkId: String, data: Data)
    case ensureReadableMirror(bookmarkId: String, document: String)
    case onDeleteNoteInlineAsset(bookmarkId: String, assetId: String)

    case onSetReaderTheme(ReaderTheme)
    case onSetReaderFontSize(ReaderFontSize)
    case onSetReaderLineHeight(ReaderLineHeight)
}
