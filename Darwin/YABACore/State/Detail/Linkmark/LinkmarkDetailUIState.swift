//
//  LinkmarkDetailUIState.swift
//  YABACore
//

import Foundation

/// Folder picked by the user + sanitized file base name; consumed by `LinkmarkReadItLaterWebView` to snapshot the reader and write `<parent>/<base>.pdf`.
public struct LinkmarkReaderPdfExport: Equatable, Sendable {
    public var parentDirectory: URL
    public var fileBaseName: String

    public init(parentDirectory: URL, fileBaseName: String) {
        self.parentDirectory = parentDirectory
        self.fileBaseName = fileBaseName
    }
}

public struct LinkmarkDetailUIState: Sendable {
    public var bookmarkId: String?
    /// Resolved link URL (set via [LinkmarkDetailEvent.onLinkSourceUrl]).
    public var linkSourceUrl: String?
    public var readerTheme: ReaderTheme
    public var readerFontSize: ReaderFontSize
    public var readerLineHeight: ReaderLineHeight
    public var lastExportMarkdown: String?
    public var lastExportPdfBase64: String?
    public var reminderDate: Date?
    public var hasNotificationPermission: Bool
    public var readerWebInitialLoadResultJson: String?

    public var showDetailSheet: Bool
    public var showEditSheet: Bool
    public var showMoveSheet: Bool
    public var showShareURLSheet: Bool
    public var showReminderSheet: Bool
    public var showDeleteAlert: Bool
    public var showActivitySheet: Bool

    public var markdownExportRequest: MarkdownExportRequest?
    public var showMarkdownExportDirectoryPicker: Bool
    public var showPdfExportDirectoryPicker: Bool
    public var pdfExportFileBaseName: String
    public var readerPdfExport: LinkmarkReaderPdfExport?
    public var readerChromeVisible: Bool

    public init(
        bookmarkId: String? = nil,
        linkSourceUrl: String? = nil,
        readerTheme: ReaderTheme = .system,
        readerFontSize: ReaderFontSize = .medium,
        readerLineHeight: ReaderLineHeight = .normal,
        lastExportMarkdown: String? = nil,
        lastExportPdfBase64: String? = nil,
        reminderDate: Date? = nil,
        hasNotificationPermission: Bool = false,
        readerWebInitialLoadResultJson: String? = nil,
        showDetailSheet: Bool = false,
        showEditSheet: Bool = false,
        showMoveSheet: Bool = false,
        showShareURLSheet: Bool = false,
        showReminderSheet: Bool = false,
        showDeleteAlert: Bool = false,
        showActivitySheet: Bool = false,
        markdownExportRequest: MarkdownExportRequest? = nil,
        showMarkdownExportDirectoryPicker: Bool = false,
        showPdfExportDirectoryPicker: Bool = false,
        pdfExportFileBaseName: String = "",
        readerPdfExport: LinkmarkReaderPdfExport? = nil,
        readerChromeVisible: Bool = true
    ) {
        self.bookmarkId = bookmarkId
        self.linkSourceUrl = linkSourceUrl
        self.readerTheme = readerTheme
        self.readerFontSize = readerFontSize
        self.readerLineHeight = readerLineHeight
        self.lastExportMarkdown = lastExportMarkdown
        self.lastExportPdfBase64 = lastExportPdfBase64
        self.reminderDate = reminderDate
        self.hasNotificationPermission = hasNotificationPermission
        self.readerWebInitialLoadResultJson = readerWebInitialLoadResultJson
        self.showDetailSheet = showDetailSheet
        self.showEditSheet = showEditSheet
        self.showMoveSheet = showMoveSheet
        self.showShareURLSheet = showShareURLSheet
        self.showReminderSheet = showReminderSheet
        self.showDeleteAlert = showDeleteAlert
        self.showActivitySheet = showActivitySheet
        self.markdownExportRequest = markdownExportRequest
        self.showMarkdownExportDirectoryPicker = showMarkdownExportDirectoryPicker
        self.showPdfExportDirectoryPicker = showPdfExportDirectoryPicker
        self.pdfExportFileBaseName = pdfExportFileBaseName
        self.readerPdfExport = readerPdfExport
        self.readerChromeVisible = readerChromeVisible
    }
}
