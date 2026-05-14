//
//  YABANavigationView.swift
//  YABA
//
//  Created by Ali Taha on 18.04.2025.
//

import SwiftUI

/// Root shell for the Darwin UI rebuild. Previous navigation (home, detail, onboarding, etc.) is archived
/// under `YABA/Home`, `YABA/Detail`, `YABA/Onboarding`, and related folders.
struct YabaNavigationView: View {
    /// Caps the middle column width so folder/tag/search lists cannot expand to full window and squeeze bookmark detail.
    private static let splitContentColumnMinWidth: CGFloat = 280
    private static let splitContentColumnIdealWidth: CGFloat = 400
    private static let splitContentColumnMaxWidth: CGFloat = 560

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State
    private var detailRouter = DetailColumnRouter()

    @State
    private var columnVisibility: NavigationSplitViewVisibility = .all

    @State
    private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    private var shouldUseCompactNavigation: Bool {
        UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if shouldUseCompactNavigation {
                NavigationStack(path: Bindable(detailRouter).navigationPath) {
                    homeContent
                        .navigationDestination(for: DetailDestination.self) { destination in
                            destinationView(for: destination, showsBackButton: true)
                        }
                }
            } else {
                NavigationSplitView(
                    columnVisibility: $columnVisibility,
                    preferredCompactColumn: $preferredCompactColumn
                ) {
                    homeContent
                } content: {
                    splitMiddleColumn
                        .navigationSplitViewColumnWidth(
                            min: Self.splitContentColumnMinWidth,
                            ideal: Self.splitContentColumnIdealWidth,
                            max: Self.splitContentColumnMaxWidth
                        )
                } detail: {
                    splitDetailColumn
                }
                .navigationSplitViewStyle(.balanced)
            }
            CoreToastOverlayView()
        }
    }

    @ViewBuilder
    private var splitMiddleColumn: some View {
        switch detailRouter.splitMiddleContent {
        case nil:
            DetailColumnPlaceholderView()
        case .search:
            SearchView(
                onSelectBookmark: { detailRouter.openBookmark(id: $0, isCompact: false) },
                showsBackButton: false
            )
        case let .folder(id):
            FolderDetailView(
                folderId: id,
                onSelectBookmark: { detailRouter.openBookmark(id: $0, isCompact: false) },
                showsBackButton: false
            )
        case let .tag(id):
            TagDetailView(
                tagId: id,
                onSelectBookmark: { detailRouter.openBookmark(id: $0, isCompact: false) },
                showsBackButton: false
            )
        }
    }

    @ViewBuilder
    private var splitDetailColumn: some View {
        if let bookmarkId = detailRouter.splitSelectedBookmarkId {
            BookmarkDetailRouterView(
                bookmarkId: bookmarkId,
                onOpenFolder: { detailRouter.openFolder(id: $0, isCompact: false) },
                onOpenTag: { detailRouter.openTag(id: $0, isCompact: false) },
                onOpenBookmark: { detailRouter.openBookmark(id: $0, isCompact: false) },
                showsBackButton: false
            )
        } else {
            BookmarkDetailPlaceholderView()
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        HomeView(
            onOpenSearch: { detailRouter.openSearch(isCompact: shouldUseCompactNavigation) },
            onSelectFolder: { detailRouter.openFolder(id: $0, isCompact: shouldUseCompactNavigation) },
            onSelectTag: { detailRouter.openTag(id: $0, isCompact: shouldUseCompactNavigation) },
            onSelectBookmark: { detailRouter.openBookmark(id: $0, isCompact: shouldUseCompactNavigation) },
            onCreatedBookmarkNavigate: { detailRouter.openBookmark(id: $0, isCompact: shouldUseCompactNavigation) },
            onBulkDeleteCompleted: { detailRouter.clearNavigationAfterBulkDataDelete() }
        )
    }

    @ViewBuilder
    private func destinationView(for destination: DetailDestination, showsBackButton: Bool) -> some View {
        let onOpenBookmark: (String) -> Void = { id in
            detailRouter.openBookmark(id: id, isCompact: true)
        }
        switch destination {
        case .search:
            SearchView(onSelectBookmark: onOpenBookmark, showsBackButton: showsBackButton)
        case let .folder(id):
            FolderDetailView(folderId: id, onSelectBookmark: onOpenBookmark, showsBackButton: showsBackButton)
        case let .tag(id):
            TagDetailView(tagId: id, onSelectBookmark: onOpenBookmark, showsBackButton: showsBackButton)
        case let .bookmark(id):
            BookmarkDetailRouterView(
                bookmarkId: id,
                onOpenFolder: { folderId in
                    detailRouter.openFolder(id: folderId, isCompact: true)
                },
                onOpenTag: { tagId in
                    detailRouter.openTag(id: tagId, isCompact: true)
                },
                onOpenBookmark: onOpenBookmark,
                showsBackButton: showsBackButton
            )
        }
    }
}
