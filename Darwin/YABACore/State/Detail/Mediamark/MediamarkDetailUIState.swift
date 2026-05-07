//
//  MediamarkDetailUIState.swift
//  YABACore
//

import Foundation

public struct MediamarkDetailUIState: Sendable {
    public var bookmarkId: String?
    public var reminderDate: Date?
    public var pendingShareFileURL: URL?

    public init(
        bookmarkId: String? = nil,
        reminderDate: Date? = nil,
        pendingShareFileURL: URL? = nil
    ) {
        self.bookmarkId = bookmarkId
        self.reminderDate = reminderDate
        self.pendingShareFileURL = pendingShareFileURL
    }
}
