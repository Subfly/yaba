//
//  NotemarkDetailUIState.swift
//  YABACore
//

import Foundation

public struct NotemarkDetailUIState: Sendable {
    public var bookmarkId: String?
    public var inlineImageDocumentSrc: String?
    public var lastExportMarkdown: String?
    public var lastExportPdfBase64: String?
    public var reminderDate: Date?
    public var webInitialContentLoadResultJson: String?

    public init(
        bookmarkId: String? = nil,
        inlineImageDocumentSrc: String? = nil,
        lastExportMarkdown: String? = nil,
        lastExportPdfBase64: String? = nil,
        reminderDate: Date? = nil,
        webInitialContentLoadResultJson: String? = nil
    ) {
        self.bookmarkId = bookmarkId
        self.inlineImageDocumentSrc = inlineImageDocumentSrc
        self.lastExportMarkdown = lastExportMarkdown
        self.lastExportPdfBase64 = lastExportPdfBase64
        self.reminderDate = reminderDate
        self.webInitialContentLoadResultJson = webInitialContentLoadResultJson
    }
}
