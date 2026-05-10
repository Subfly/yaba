//
//  DocmarkCreationStateMachine.swift
//  YABACore
//

import Foundation
import SwiftUI

@MainActor
public final class DocmarkCreationStateMachine: YabaBaseObservableState<DocmarkCreationUIState>, YabaScreenStateMachine {
    /// Increments on each new document pick so stale extraction work does not apply.
    private var documentExtractionGeneration: Int = 0

    public override init(initialState: DocmarkCreationUIState = DocmarkCreationUIState()) {
        super.init(initialState: initialState)
    }

    public func send(_ event: DocmarkCreationEvent) async {
        switch event {
        case let .onInit(id, folderId, tagIds, uncategorizedFolderCreationRequired, creationDocmarkKind):
            apply {
                $0.editingBookmarkId = id
                $0.selectedFolderId = folderId
                $0.selectedTagIds = tagIds ?? []
                if id == nil {
                    $0.uncategorizedFolderCreationRequired = uncategorizedFolderCreationRequired
                    $0.creationDocmarkKind = creationDocmarkKind
                    $0.docmarkType = creationDocmarkKind
                } else {
                    $0.uncategorizedFolderCreationRequired = false
                }
            }
        case .onPickDocument:
            break
        case .onClearDocument:
            documentExtractionGeneration += 1
            apply {
                $0.pickedDocumentData = nil
                $0.sourceFileName = nil
                $0.selectedFilePath = nil
                $0.previewImageData = nil
                $0.isLoading = false
                $0.lastError = nil
            }
        case let .onDocumentFromShare(data, name, selectedPath, docType):
            documentExtractionGeneration += 1
            let generation = documentExtractionGeneration
            apply {
                $0.pickedDocumentData = data
                $0.sourceFileName = name
                $0.selectedFilePath = selectedPath
                $0.docmarkType = docType
                $0.previewImageData = nil
                $0.isLoading = docType == .pdf || docType == .epub
                $0.lastError = nil
            }
            switch docType {
            case .pdf:
                Task { await self.extractPdfPreview(data: data, generation: generation) }
            case .csv:
                Task { await self.send(.onDocumentExtractionFinished) }
            case .epub:
                Task { await self.extractEpubCoverPreview(data: data, generation: generation) }
            }
        case .onCyclePreviewAppearance:
            apply {
                switch $0.bookmarkAppearance {
                case .list: $0.bookmarkAppearance = .card
                case .card: $0.bookmarkAppearance = .grid
                case .grid: $0.bookmarkAppearance = .list
                }
            }
        case let .onSetGeneratedPreview(data, _):
            apply { $0.previewImageData = data }
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
        case .onDocumentExtractionFinished:
            apply { $0.isLoading = false }
        case .onSave:
            await persist()
        case .onTogglePinned:
            apply { $0.isPinned.toggle() }
        case let .create(bookmarkId, folderId, label, bookmarkDescription, isPinned, tagIds):
            AllBookmarksManager.queueCreateBookmark(
                bookmarkId: bookmarkId,
                folderId: folderId,
                kind: .file,
                label: label,
                bookmarkDescription: bookmarkDescription,
                isPinned: isPinned,
                tagIds: tagIds
            )
            DocmarkManager.queueEnsureInitialDocDetail(bookmarkId: bookmarkId)
        }
    }

    private func persist() async {
        let folderId = state.selectedFolderId
        let trimmedLabel = state.label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else {
            apply { $0.lastError = "Label required" }
            return
        }
        let label = trimmedLabel
        guard let folderId, !folderId.isEmpty else {
            apply { $0.lastError = "Folder required" }
            return
        }
        if state.editingBookmarkId == nil {
            guard state.pickedDocumentData != nil else {
                apply { $0.lastError = "No document selected" }
                return
            }
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
        apply { $0.lastError = nil; $0.isSaving = true }
        let bid = state.editingBookmarkId ?? UUID().uuidString
        let summary = state.summary.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        if state.editingBookmarkId != nil {
            AllBookmarksManager.queueUpdateBookmarkMetadata(
                bookmarkId: bid,
                folderId: folderId,
                kind: .file,
                label: label,
                bookmarkDescription: state.bookmarkDescription.nilIfEmpty,
                isPinned: state.isPinned,
                tagIds: state.selectedTagIds
            )
        } else {
            AllBookmarksManager.queueCreateBookmark(
                bookmarkId: bid,
                folderId: folderId,
                kind: .file,
                label: label,
                bookmarkDescription: state.bookmarkDescription.nilIfEmpty,
                isPinned: state.isPinned,
                tagIds: state.selectedTagIds
            )
            AllBookmarksManager.queueSetBookmarkPreviewAssets(
                bookmarkId: bid,
                imageBytes: state.previewImageData,
                iconBytes: nil
            )
        }
        DocmarkManager.queueCreateOrUpdateDocDetails(
            bookmarkId: bid,
            summary: summary,
            docmarkType: state.editingBookmarkId != nil ? nil : state.docmarkType
        )
        if state.editingBookmarkId == nil, let docBytes = state.pickedDocumentData {
            DocmarkManager.queueUpsertDocBookmarkPayloadBytes(bookmarkId: bid, documentBytes: docBytes)
        }
        apply { $0.isSaving = false }
    }

    private func extractPdfPreview(data: Data, generation: Int) async {
        let previewPNG: Data? = await Task.detached(priority: .userInitiated) {
            PDFPreviewExtractor.firstPagePNG(from: data)
        }.value

        guard generation == documentExtractionGeneration else { return }
        await send(
            .onSetGeneratedPreview(
                imageData: previewPNG,
                fileExtension: "png"
            )
        )
        await send(.onDocumentExtractionFinished)
    }

    private func extractEpubCoverPreview(data: Data, generation: Int) async {
        let cover: Data? = await Task.detached(priority: .userInitiated) {
            EPUBCoverExtractor.coverImageData(from: data)
        }.value

        guard generation == documentExtractionGeneration else { return }

        await send(
            .onSetGeneratedPreview(
                imageData: cover,
                fileExtension: "png"
            )
        )

        await send(.onDocumentExtractionFinished)
    }
}
