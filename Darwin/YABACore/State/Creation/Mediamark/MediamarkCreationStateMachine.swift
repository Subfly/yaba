//
//  MediamarkCreationStateMachine.swift
//  YABACore
//

import Foundation

@MainActor
public final class MediamarkCreationStateMachine: YabaBaseObservableState<MediamarkCreationUIState>, YabaScreenStateMachine {
    public override init(initialState: MediamarkCreationUIState = MediamarkCreationUIState()) {
        super.init(initialState: initialState)
    }

    public func send(_ event: MediamarkCreationEvent) async {
        switch event {
        case let .onInit(
            mediaBookmarkId: id,
            initialFolderId: folderId,
            initialTagIds: tagIds,
            uncategorizedFolderCreationRequired: uncategorizedFolderCreationRequired,
            initialMediaMarkType: initialMediaMarkType
        ):
            apply {
                $0.editingBookmarkId = id
                $0.selectedFolderId = folderId
                $0.selectedTagIds = tagIds ?? []
                $0.mediaMarkType = initialMediaMarkType
                if initialMediaMarkType == .image {
                    $0.mediaFileExtension = "png"
                } else if initialMediaMarkType == .video {
                    $0.mediaFileExtension = "mp4"
                } else if initialMediaMarkType == .audio {
                    $0.mediaFileExtension = "wav"
                }
                if id == nil {
                    $0.uncategorizedFolderCreationRequired = uncategorizedFolderCreationRequired
                } else {
                    $0.uncategorizedFolderCreationRequired = false
                }
            }
        case .onCyclePreviewAppearance:
            apply {
                switch $0.bookmarkAppearance {
                case .list: $0.bookmarkAppearance = .card
                case .card: $0.bookmarkAppearance = .grid
                case .grid: $0.bookmarkAppearance = .list
                }
            }
        case .onPickFromGallery, .onCaptureFromCamera:
            break
        case let .onImageFromShare(data, ext, selectedPath):
            apply {
                $0.mediaMarkType = .image
                $0.imageData = data
                $0.videoData = nil
                $0.audioData = nil
                $0.mediaFileExtension = ext
                $0.selectedFilePath = selectedPath
            }
        case let .onVideoPicked(videoData, thumbnailData, ext, selectedPath):
            apply {
                $0.mediaMarkType = .video
                $0.videoData = videoData
                $0.imageData = thumbnailData
                $0.audioData = nil
                $0.mediaFileExtension = ext.isEmpty ? "mp4" : ext
                $0.selectedFilePath = selectedPath
            }
        case let .onAudioPicked(audioData, ext, selectedPath):
            apply {
                $0.mediaMarkType = .audio
                $0.audioData = audioData
                $0.videoData = nil
                // Keep preview image as-is for audio (none by default).
                $0.imageData = nil
                $0.mediaFileExtension = ext.isEmpty ? "wav" : ext
                $0.selectedFilePath = selectedPath
            }
        case .onClearMedia:
            apply {
                $0.imageData = nil
                $0.videoData = nil
                $0.audioData = nil
                $0.selectedFilePath = nil
            }
        case let .onChangeLabel(s):
            apply { $0.label = s }
        case let .onChangeDescription(s):
            apply { $0.bookmarkDescription = s }
        case let .onSelectFolderId(id):
            apply {
                $0.selectedFolderId = id
                $0.uncategorizedFolderCreationRequired = false
            }
        case let .onSelectTagIds(ids):
            apply { $0.selectedTagIds = ids }
        case .onSave:
            await persist()
        case .onTogglePinned:
            apply { $0.isPinned.toggle() }
        case let .create(bookmarkId, folderId, label, bookmarkDescription, isPinned, tagIds):
            AllBookmarksManager.queueCreateBookmark(
                bookmarkId: bookmarkId,
                folderId: folderId,
                kind: .media,
                label: label,
                bookmarkDescription: bookmarkDescription,
                isPinned: isPinned,
                tagIds: tagIds
            )
            MediamarkManager.queueCreateOrUpdateMediaDetails(
                bookmarkId: bookmarkId,
                originalData: nil,
                mediaMarkType: state.mediaMarkType
            )
        }
    }

    private func persist() async {
        let folderId = state.selectedFolderId
        let label = state.label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let folderId, !folderId.isEmpty else {
            apply { $0.lastError = "Folder required" }
            return
        }
        if state.uncategorizedFolderCreationRequired {
            do {
                try await CoreOperationQueue.shared.queueAndAwait(name: "EnsureUncategorizedFolderVisible") { context in
                    try FolderManager.ensureUncategorizedFolderVisibleInContext(context)
                }
                apply { $0.uncategorizedFolderCreationRequired = false }
            } catch {
                apply {
                    $0.lastError = String(describing: error)
                    $0.isSaving = false
                }
                return
            }
        }
        guard !label.isEmpty else {
            apply { $0.lastError = "Label required" }
            return
        }

        let markType = state.mediaMarkType
        if markType == .video, state.editingBookmarkId == nil {
            guard let vData = state.videoData, !vData.isEmpty else {
                apply { $0.lastError = "Video required" }
                return
            }
        }
        if markType == .audio, state.editingBookmarkId == nil {
            guard let aData = state.audioData, !aData.isEmpty else {
                apply { $0.lastError = "Audio required" }
                return
            }
        }

        apply { $0.lastError = nil; $0.isSaving = true }
        let bid = state.editingBookmarkId ?? UUID().uuidString
        if state.editingBookmarkId != nil {
            AllBookmarksManager.queueUpdateBookmarkMetadata(
                bookmarkId: bid,
                folderId: folderId,
                kind: .media,
                label: label,
                bookmarkDescription: state.bookmarkDescription.nilIfEmpty,
                isPinned: state.isPinned,
                tagIds: state.selectedTagIds
            )
        } else {
            AllBookmarksManager.queueCreateBookmark(
                bookmarkId: bid,
                folderId: folderId,
                kind: .media,
                label: label,
                bookmarkDescription: state.bookmarkDescription.nilIfEmpty,
                isPinned: state.isPinned,
                tagIds: state.selectedTagIds
            )
        }

        switch markType {
        case .image:
            if let data = state.imageData {
                AllBookmarksManager.queueSetBookmarkPreviewAssets(
                    bookmarkId: bid,
                    imageBytes: data,
                    iconBytes: nil
                )
                MediamarkManager.queueCreateOrUpdateMediaDetails(
                    bookmarkId: bid,
                    originalData: data,
                    mediaMarkType: .image
                )
            } else {
                MediamarkManager.queueCreateOrUpdateMediaDetails(
                    bookmarkId: bid,
                    originalData: nil,
                    mediaMarkType: .image
                )
            }
        case .video:
            if let thumb = state.imageData {
                AllBookmarksManager.queueSetBookmarkPreviewAssets(
                    bookmarkId: bid,
                    imageBytes: thumb,
                    iconBytes: nil
                )
            }
            if let v = state.videoData {
                MediamarkManager.queueCreateOrUpdateMediaDetails(
                    bookmarkId: bid,
                    originalData: v,
                    mediaMarkType: .video
                )
            } else if state.editingBookmarkId != nil {
                MediamarkManager.queueCreateOrUpdateMediaDetails(
                    bookmarkId: bid,
                    originalData: nil,
                    mediaMarkType: .video
                )
            }
        case .audio:
            if let a = state.audioData {
                MediamarkManager.queueCreateOrUpdateMediaDetails(
                    bookmarkId: bid,
                    originalData: a,
                    mediaMarkType: .audio
                )
            } else if state.editingBookmarkId != nil {
                MediamarkManager.queueCreateOrUpdateMediaDetails(
                    bookmarkId: bid,
                    originalData: nil,
                    mediaMarkType: .audio
                )
            }
        }

        apply { $0.isSaving = false }
    }
}
