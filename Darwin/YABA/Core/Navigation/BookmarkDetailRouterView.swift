//
//  BookmarkDetailRouterView.swift
//  YABA
//
//  Routes bookmark detail destinations by `BookmarkKind` (link, media, file, note, etc.).
//

import SwiftData
import SwiftUI

struct BookmarkDetailRouterView: View {
    let bookmarkId: String
    let onOpenFolder: (String) -> Void
    let onOpenTag: (String) -> Void
    let onOpenBookmark: (String) -> Void
    var showsBackButton: Bool = true

    @Query
    private var bookmarks: [YabaBookmark]

    init(
        bookmarkId: String,
        onOpenFolder: @escaping (String) -> Void = { _ in },
        onOpenTag: @escaping (String) -> Void = { _ in },
        onOpenBookmark: @escaping (String) -> Void = { _ in },
        showsBackButton: Bool = true
    ) {
        self.bookmarkId = bookmarkId
        self.onOpenFolder = onOpenFolder
        self.onOpenTag = onOpenTag
        self.onOpenBookmark = onOpenBookmark
        self.showsBackButton = showsBackButton
        var d = FetchDescriptor<YabaBookmark>(
            predicate: #Predicate<YabaBookmark> { $0.bookmarkId == bookmarkId }
        )
        d.fetchLimit = 1
        _bookmarks = Query(d, animation: .smooth)
    }

    var body: some View {
        Group {
            if let bm = bookmarks.first {
                switch bm.kind {
                case .link:
                    LinkmarkDetailView(
                        bookmarkId: bookmarkId,
                        onOpenFolder: onOpenFolder,
                        onOpenTag: onOpenTag,
                        showsBackButton: showsBackButton
                    )
                case .media:
                    MediamarkDetailView(
                        bookmarkId: bookmarkId,
                        onOpenFolder: onOpenFolder,
                        onOpenTag: onOpenTag,
                        showsBackButton: showsBackButton
                    )
                case .file:
                    DocmarkDetailView(
                        bookmarkId: bookmarkId,
                        onOpenFolder: onOpenFolder,
                        onOpenTag: onOpenTag,
                        showsBackButton: showsBackButton
                    )
                case .note:
                    NotemarkDetailView(
                        bookmarkId: bookmarkId,
                        onOpenFolder: onOpenFolder,
                        onOpenTag: onOpenTag,
                        onOpenBookmark: onOpenBookmark,
                        showsBackButton: showsBackButton
                    )
                }
            } else {
                EmptyView()
            }
        }
    }
}
