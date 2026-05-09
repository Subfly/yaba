//
//  NotemarkDetailUIState.swift
//  YABACore
//

import Foundation

public struct NotemarkDetailUIState: Sendable {
    public var bookmarkId: String?
    public var inlineImageDocumentSrc: String?
    public var lastExportMarkdown: String?
    public var reminderDate: Date?
    public var webInitialContentLoadResult: String?

    /// Editor chrome (`editor.html`) typography / theme (parity with link reader prefs).
    public var readerTheme: ReaderTheme
    public var readerFontSize: ReaderFontSize
    public var readerLineHeight: ReaderLineHeight

    /// `.editor`: CodeMirror (`editor.html`); `.preview`: rendered Markdown (`preview.html`).
    public var surfaceMode: NotemarkDetailSurfaceMode

    public var showDetailSheet: Bool
    public var showEditSheet: Bool
    public var showMoveSheet: Bool
    public var showReminderSheet: Bool
    public var showDeleteAlert: Bool

    public var markdownExportRequest: MarkdownExportRequest?
    public var showMarkdownExportDirectoryPicker: Bool

    public init(
        bookmarkId: String? = nil,
        inlineImageDocumentSrc: String? = nil,
        lastExportMarkdown: String? = nil,
        reminderDate: Date? = nil,
        webInitialContentLoadResult: String? = nil,
        readerTheme: ReaderTheme = .system,
        readerFontSize: ReaderFontSize = .medium,
        readerLineHeight: ReaderLineHeight = .normal,
        surfaceMode: NotemarkDetailSurfaceMode = .editor,
        showDetailSheet: Bool = false,
        showEditSheet: Bool = false,
        showMoveSheet: Bool = false,
        showReminderSheet: Bool = false,
        showDeleteAlert: Bool = false,
        markdownExportRequest: MarkdownExportRequest? = nil,
        showMarkdownExportDirectoryPicker: Bool = false
    ) {
        self.bookmarkId = bookmarkId
        self.inlineImageDocumentSrc = inlineImageDocumentSrc
        self.lastExportMarkdown = lastExportMarkdown
        self.reminderDate = reminderDate
        self.webInitialContentLoadResult = webInitialContentLoadResult
        self.readerTheme = readerTheme
        self.readerFontSize = readerFontSize
        self.readerLineHeight = readerLineHeight
        self.surfaceMode = surfaceMode
        self.showDetailSheet = showDetailSheet
        self.showEditSheet = showEditSheet
        self.showMoveSheet = showMoveSheet
        self.showReminderSheet = showReminderSheet
        self.showDeleteAlert = showDeleteAlert
        self.markdownExportRequest = markdownExportRequest
        self.showMarkdownExportDirectoryPicker = showMarkdownExportDirectoryPicker
    }
}
