//
//  DocmarkDetailUIState.swift
//  YABACore
//

import Foundation

public struct DocmarkDetailUIState: Sendable {
    public var bookmarkId: String?
    public var reminderDate: Date?
    /// Populated by `onShareDocument`; clear with `onConsumePendingShare` after the share sheet dismisses.
    public var pendingShareFileURL: URL?
    public var showDocumentSaveCopyPicker: Bool
    public var documentSaveCopyFileBaseName: String

    /// EPUB Readium navigator preferences (docmark detail only).
    public var epubReaderTheme: ReaderTheme
    public var epubReaderFontSize: ReaderFontSize
    public var epubReaderLineHeight: ReaderLineHeight

    public init(
        bookmarkId: String? = nil,
        reminderDate: Date? = nil,
        pendingShareFileURL: URL? = nil,
        showDocumentSaveCopyPicker: Bool = false,
        documentSaveCopyFileBaseName: String = "",
        epubReaderTheme: ReaderTheme = .system,
        epubReaderFontSize: ReaderFontSize = .medium,
        epubReaderLineHeight: ReaderLineHeight = .normal
    ) {
        self.bookmarkId = bookmarkId
        self.reminderDate = reminderDate
        self.pendingShareFileURL = pendingShareFileURL
        self.showDocumentSaveCopyPicker = showDocumentSaveCopyPicker
        self.documentSaveCopyFileBaseName = documentSaveCopyFileBaseName
        self.epubReaderTheme = epubReaderTheme
        self.epubReaderFontSize = epubReaderFontSize
        self.epubReaderLineHeight = epubReaderLineHeight
    }
}
