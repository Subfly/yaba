//
//  BookmarkShareLaunchBuilder.swift
//  YABA
//
//  Maps a resolved payload to the bookmark kind / subtype used by ``BookmarkKindForm``.
//

import Foundation

enum BookmarkShareLaunchBuilder {
    /// Build a sheet launch describing which creation form opens and retains the originating payload on ``BookmarkKindFormLaunch``.
    static func formLaunch(for payload: BookmarkShareIncomingPayload) -> BookmarkKindFormLaunch {
        switch payload {
        case .link:
            BookmarkKindFormLaunch(
                kind: .link,
                preselectedFolderId: nil,
                preselectedTagIds: [],
                mediaMarkType: nil,
                docmarkType: nil,
                initialSharePayload: payload,
                locksImportedPrimaryPayload: true
            )
        case let .document(_, _, docKind):
            BookmarkKindFormLaunch(
                kind: .file,
                preselectedFolderId: nil,
                preselectedTagIds: [],
                mediaMarkType: nil,
                docmarkType: docKind,
                initialSharePayload: payload,
                locksImportedPrimaryPayload: true
            )
        case .image:
            BookmarkKindFormLaunch(
                kind: .media,
                preselectedFolderId: nil,
                preselectedTagIds: [],
                mediaMarkType: .image,
                docmarkType: nil,
                initialSharePayload: payload,
                locksImportedPrimaryPayload: true
            )
        case .audio:
            BookmarkKindFormLaunch(
                kind: .media,
                preselectedFolderId: nil,
                preselectedTagIds: [],
                mediaMarkType: .audio,
                docmarkType: nil,
                initialSharePayload: payload,
                locksImportedPrimaryPayload: true
            )
        case .video:
            BookmarkKindFormLaunch(
                kind: .media,
                preselectedFolderId: nil,
                preselectedTagIds: [],
                mediaMarkType: .video,
                docmarkType: nil,
                initialSharePayload: payload,
                locksImportedPrimaryPayload: true
            )
        case .noteMarkdown:
            BookmarkKindFormLaunch(
                kind: .note,
                preselectedFolderId: nil,
                preselectedTagIds: [],
                mediaMarkType: nil,
                docmarkType: nil,
                initialSharePayload: payload,
                locksImportedPrimaryPayload: true
            )
        }
    }
}
