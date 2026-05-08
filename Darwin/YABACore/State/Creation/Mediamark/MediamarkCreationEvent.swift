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
        uncategorizedFolderCreationRequired: Bool,
        initialMediaMarkType: MediaMarkType
    )
    case onCyclePreviewAppearance
    case onPickFromGallery
    case onImageFromShare(Data, fileExtension: String)
    case onVideoPicked(videoData: Data, thumbnailData: Data?, fileExtension: String)
    case onAudioPicked(audioData: Data, fileExtension: String)
    case onCaptureFromCamera
    case onClearMedia
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
