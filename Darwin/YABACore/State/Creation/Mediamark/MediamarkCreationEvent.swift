//
//  MediamarkCreationEvent.swift
//  YABACore
//

import Foundation

public enum MediamarkCreationEvent: Sendable {
    case onInit(
        mediaBookmarkId: String?,
        initialFolderId: String?,
        initialTagIds: [String]?,
        uncategorizedFolderCreationRequired: Bool
    )
    case onCyclePreviewAppearance
    case onPickFromGallery
    case onImageFromShare(Data, fileExtension: String)
    case onCaptureFromCamera
    case onClearImage
    case onChangeLabel(String)
    case onChangeDescription(String)
    case onSelectFolderId(String?)
    case onSelectTagIds([String])
    case onSave
    case onTogglePinned

    case create(
        bookmarkId: String,
        folderId: String,
        label: String,
        bookmarkDescription: String?,
        isPinned: Bool,
        tagIds: [String]
    )
}
