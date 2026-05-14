//
//  DetailColumnRouter.swift
//  YABA
//
//  Drives navigation: compact phone uses `NavigationPath`; regular width uses split column selection.
//

import SwiftUI

enum DetailDestination: Hashable, Sendable {
    case search
    case folder(String)
    case tag(String)
    case bookmark(String)
}

/// Middle column selection when using three-column `NavigationSplitView` (iPad / Mac Catalyst).
enum SplitMiddleContent: Hashable, Sendable {
    case search
    case folder(String)
    case tag(String)
}

@MainActor
@Observable
final class DetailColumnRouter {
    /// iPhone / compact horizontal: stack-based navigation.
    var navigationPath = NavigationPath()

    /// iPad / Mac / regular width: replaces middle column (nil → collection placeholder).
    var splitMiddleContent: SplitMiddleContent?

    /// iPad / Mac / regular width: replaces detail column bookmark (nil → bookmark placeholder).
    var splitSelectedBookmarkId: String?

    func openSearch(isCompact: Bool) {
        if isCompact {
            navigationPath.append(DetailDestination.search)
        } else {
            splitMiddleContent = .search
        }
    }

    func openFolder(id: String, isCompact: Bool) {
        if isCompact {
            navigationPath.append(DetailDestination.folder(id))
        } else {
            splitMiddleContent = .folder(id)
        }
    }

    func openTag(id: String, isCompact: Bool) {
        if isCompact {
            navigationPath.append(DetailDestination.tag(id))
        } else {
            splitMiddleContent = .tag(id)
        }
    }

    func openBookmark(id: String, isCompact: Bool) {
        if isCompact {
            navigationPath.append(DetailDestination.bookmark(id))
        } else {
            splitSelectedBookmarkId = id
        }
    }

    /// Clears navigation after all bookmarks/collections were removed (e.g. Settings delete all).
    func clearNavigationAfterBulkDataDelete() {
        splitSelectedBookmarkId = nil
        splitMiddleContent = nil
        navigationPath = NavigationPath()
    }
}
