//
//  BookmarkCreationSelectedContentIndicator.swift
//  YABA
//
//  Compact path row shown after the user selects primary bookmark payload (media / documents).
//

import SwiftUI

/// Display-only path string (real security-scoped path, temp capture path, or synthetic import path).
struct BookmarkCreationSelectedContentIndicator: View {
    let path: String
    /// Folder / screen tint (matches other bookmark-creation icons).
    let mainTint: Color

    var body: some View {
        Label {
            Text(path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            YabaIconView(bundleKey: "hierarchy-files")
                .frame(width: 18, height: 18)
                .foregroundStyle(mainTint)
        }
        .labelIconToTitleSpacing(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowInsets(.all, 0)
    }
}

enum BookmarkCreationSelectedPathFactory {

    /// Temp-style path for payloads that are not backed by a durable filesystem URL.
    static func syntheticImportPath(prefix: String, fileName: String) -> String {
        let sanitized = (fileName as NSString).lastPathComponent
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)-\(sanitized)")
            .path
    }

    static func syntheticDocumentSharePath(fileName: String?, docmarkType: DocmarkType) -> String {
        let fallbackName: String
        switch docmarkType {
        case .pdf:
            fallbackName = "document.pdf"
        case .csv:
            fallbackName = "document.csv"
        case .epub:
            fallbackName = "document.epub"
        }
        let candidate = fileName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = candidate.nilIfEmpty ?? fallbackName
        return syntheticImportPath(prefix: "yaba-share-doc", fileName: name)
    }

    static func syntheticMediaSharePath(fileExtension: String) -> String {
        let ext = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "bin"
        return syntheticImportPath(prefix: "yaba-share-media", fileName: "import.\(ext)")
    }
}
