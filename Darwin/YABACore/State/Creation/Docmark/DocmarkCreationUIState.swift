//
//  DocmarkCreationUIState.swift
//  YABACore
//

import Foundation

public struct DocmarkCreationUIState: Sendable {
    public var editingBookmarkId: String?
    public var label: String
    public var bookmarkDescription: String
    public var summary: String
    public var selectedFolderId: String?
    public var uncategorizedFolderCreationRequired: Bool
    public var selectedTagIds: [String]
    public var docmarkType: DocmarkType?
    public var creationDocmarkKind: DocmarkType
    public var pickedDocumentData: Data?
    public var sourceFileName: String?
    public var selectedFilePath: String?
    public var previewImageData: Data?
    public var isLoading: Bool
    public var bookmarkAppearance: BookmarkAppearance
    public var cardImageSizing: CardImageSizing
    public var isPinned: Bool
    public var isSaving: Bool
    public var lastError: String?

    public init(
        editingBookmarkId: String? = nil,
        label: String = "",
        bookmarkDescription: String = "",
        summary: String = "",
        selectedFolderId: String? = nil,
        uncategorizedFolderCreationRequired: Bool = false,
        selectedTagIds: [String] = [],
        docmarkType: DocmarkType? = nil,
        creationDocmarkKind: DocmarkType = .pdf,
        pickedDocumentData: Data? = nil,
        sourceFileName: String? = nil,
        selectedFilePath: String? = nil,
        previewImageData: Data? = nil,
        isLoading: Bool = false,
        bookmarkAppearance: BookmarkAppearance = .list,
        cardImageSizing: CardImageSizing = .small,
        isPinned: Bool = false,
        isSaving: Bool = false,
        lastError: String? = nil
    ) {
        self.editingBookmarkId = editingBookmarkId
        self.label = label
        self.bookmarkDescription = bookmarkDescription
        self.summary = summary
        self.selectedFolderId = selectedFolderId
        self.uncategorizedFolderCreationRequired = uncategorizedFolderCreationRequired
        self.selectedTagIds = selectedTagIds
        self.docmarkType = docmarkType
        self.creationDocmarkKind = creationDocmarkKind
        self.pickedDocumentData = pickedDocumentData
        self.sourceFileName = sourceFileName
        self.selectedFilePath = selectedFilePath
        self.previewImageData = previewImageData
        self.isLoading = isLoading
        self.bookmarkAppearance = bookmarkAppearance
        self.cardImageSizing = cardImageSizing
        self.isPinned = isPinned
        self.isSaving = isSaving
        self.lastError = lastError
    }

    public var canSave: Bool {
        let hasLabel = !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return selectedFolderId != nil
            && !(selectedFolderId?.isEmpty ?? true)
            && (editingBookmarkId != nil || pickedDocumentData != nil)
            && !isLoading
            && hasLabel
    }
}
