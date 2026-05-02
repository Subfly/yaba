//
//  CanvmarkDetailUIState.swift
//  YABACore
//

import Foundation

public struct CanvmarkDetailUIState: Sendable {
    public var bookmarkId: String?
    public var metricsJson: String?
    public var styleJson: String?
    public var pendingExportImageData: Data?
    public var pendingExportImageExtension: String
    public var reminderDate: Date?
    public var webInitialContentLoadResultJson: String?

    public var showDetailSheet: Bool
    public var showEditSheet: Bool
    public var showMoveSheet: Bool
    public var showReminderSheet: Bool
    public var showDeleteAlert: Bool
    public var exportIncludeBackground: Bool

    public init(
        bookmarkId: String? = nil,
        metricsJson: String? = nil,
        styleJson: String? = nil,
        pendingExportImageData: Data? = nil,
        pendingExportImageExtension: String = "png",
        reminderDate: Date? = nil,
        webInitialContentLoadResultJson: String? = nil,
        showDetailSheet: Bool = false,
        showEditSheet: Bool = false,
        showMoveSheet: Bool = false,
        showReminderSheet: Bool = false,
        showDeleteAlert: Bool = false,
        exportIncludeBackground: Bool = true
    ) {
        self.bookmarkId = bookmarkId
        self.metricsJson = metricsJson
        self.styleJson = styleJson
        self.pendingExportImageData = pendingExportImageData
        self.pendingExportImageExtension = pendingExportImageExtension
        self.reminderDate = reminderDate
        self.webInitialContentLoadResultJson = webInitialContentLoadResultJson
        self.showDetailSheet = showDetailSheet
        self.showEditSheet = showEditSheet
        self.showMoveSheet = showMoveSheet
        self.showReminderSheet = showReminderSheet
        self.showDeleteAlert = showDeleteAlert
        self.exportIncludeBackground = exportIncludeBackground
    }
}
