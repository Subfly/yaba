//
//  DocmarkCreationEvent.swift
//  YABACore
//

import Foundation

public enum DocmarkCreationEvent: Sendable {
    case onInit(
        docmarkId: String?,
        initialFolderId: String?,
        initialTagIds: [String]?,
        uncategorizedFolderCreationRequired: Bool,
        creationDocmarkKind: DocmarkType
    )
    case onPickDocument
    case onClearDocument
    case onDocumentFromShare(Data, sourceFileName: String?, docmarkType: DocmarkType)
    case onCyclePreviewAppearance
    case onSetGeneratedPreview(imageData: Data?, fileExtension: String)
    case onChangeLabel(String)
    case onChangeDescription(String)
    case onSelectFolderId(String?)
    case onSelectTagIds([String])
    case onDocumentExtractionFinished
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
