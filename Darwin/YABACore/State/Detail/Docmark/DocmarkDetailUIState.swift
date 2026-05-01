//
//  DocmarkDetailUIState.swift
//  YABACore
//

import Foundation

public struct DocmarkDetailUIState: Sendable {
    public var bookmarkId: String?
    public var readerTheme: ReaderTheme
    public var readerFontSize: ReaderFontSize
    public var readerLineHeight: ReaderLineHeight
    public var reminderDate: Date?
    public var webInitialContentLoadResultJson: String?

    public init(
        bookmarkId: String? = nil,
        readerTheme: ReaderTheme = .system,
        readerFontSize: ReaderFontSize = .medium,
        readerLineHeight: ReaderLineHeight = .normal,
        reminderDate: Date? = nil,
        webInitialContentLoadResultJson: String? = nil
    ) {
        self.bookmarkId = bookmarkId
        self.readerTheme = readerTheme
        self.readerFontSize = readerFontSize
        self.readerLineHeight = readerLineHeight
        self.reminderDate = reminderDate
        self.webInitialContentLoadResultJson = webInitialContentLoadResultJson
    }
}
