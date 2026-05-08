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

    public init(
        bookmarkId: String? = nil,
        reminderDate: Date? = nil,
        pendingShareFileURL: URL? = nil,
        showDocumentSaveCopyPicker: Bool = false,
        documentSaveCopyFileBaseName: String = ""
    ) {
        self.bookmarkId = bookmarkId
        self.reminderDate = reminderDate
        self.pendingShareFileURL = pendingShareFileURL
        self.showDocumentSaveCopyPicker = showDocumentSaveCopyPicker
        self.documentSaveCopyFileBaseName = documentSaveCopyFileBaseName
    }
}
