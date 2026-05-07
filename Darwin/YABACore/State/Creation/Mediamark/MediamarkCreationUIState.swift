//
//  MediamarkCreationUIState.swift
//  YABACore
//

import Foundation

public struct MediamarkCreationUIState: Sendable {
    public var editingBookmarkId: String?
    public var label: String
    public var bookmarkDescription: String
    public var selectedFolderId: String?
    public var uncategorizedFolderCreationRequired: Bool
    public var selectedTagIds: [String]
    public var mediaMarkType: MediaMarkType
    public var imageData: Data?
    public var videoData: Data?
    public var mediaFileExtension: String
    public var bookmarkAppearance: BookmarkAppearance
    public var cardImageSizing: CardImageSizing
    public var isPinned: Bool
    public var isSaving: Bool
    public var lastError: String?

    public init(
        editingBookmarkId: String? = nil,
        label: String = "",
        bookmarkDescription: String = "",
        selectedFolderId: String? = nil,
        uncategorizedFolderCreationRequired: Bool = false,
        selectedTagIds: [String] = [],
        mediaMarkType: MediaMarkType = .image,
        imageData: Data? = nil,
        videoData: Data? = nil,
        mediaFileExtension: String = "png",
        bookmarkAppearance: BookmarkAppearance = .list,
        cardImageSizing: CardImageSizing = .small,
        isPinned: Bool = false,
        isSaving: Bool = false,
        lastError: String? = nil
    ) {
        self.editingBookmarkId = editingBookmarkId
        self.label = label
        self.bookmarkDescription = bookmarkDescription
        self.selectedFolderId = selectedFolderId
        self.uncategorizedFolderCreationRequired = uncategorizedFolderCreationRequired
        self.selectedTagIds = selectedTagIds
        self.mediaMarkType = mediaMarkType
        self.imageData = imageData
        self.videoData = videoData
        self.mediaFileExtension = mediaFileExtension
        self.bookmarkAppearance = bookmarkAppearance
        self.cardImageSizing = cardImageSizing
        self.isPinned = isPinned
        self.isSaving = isSaving
        self.lastError = lastError
    }
}
