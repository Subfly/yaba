//
//  PresentableBookmarkItemView.swift
//  YABA
//
//  Picker / sheet row (nullable bookmark). List-style parity with bookmark list rows, minus menus/swipes.
//

import SwiftUI
import UIKit

/// Shared list-style bookmark row label (image + title + optional description).
struct PresentableBookmarkListRowContent: View {
    let bookmark: YabaBookmark
    var showsDisclosureChevron: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            PresentableBookmarkThumbnail(bookmark: bookmark)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                Text(bookmark.label)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if let desc = bookmark.bookmarkDescription, !desc.isEmpty {
                    Text(desc)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }

            if showsDisclosureChevron && UIDevice.current.userInterfaceIdiom == .phone {
                Spacer(minLength: 0)
                YabaIconView(bundleKey: "arrow-right-01")
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct PresentableBookmarkThumbnail: View {
    let bookmark: YabaBookmark

    var body: some View {
        Group {
            if let imageData = bookmark.imageDataHolder, let ui = UIImage(data: imageData) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipped()
            } else {
                placeholderList
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderList: some View {
        let folderTint = bookmark.getFolderColor()
        return RoundedRectangle(cornerRadius: 8)
            .fill(folderTint.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay {
                YabaIconView(bundleKey: bookmark.kind.getIconName())
                    .scaledToFit()
                    .foregroundStyle(folderTint)
                    .frame(width: 32, height: 32)
            }
    }
}

struct PresentableBookmarkItemView: View {
    let model: YabaBookmark?
    let nullModelPresentableColor: YabaColor
    let onPressed: () -> Void

    var body: some View {
        Button(action: onPressed) {
            HStack(alignment: .center) {
                if let bookmark = model {
                    PresentableBookmarkListRowContent(bookmark: bookmark, showsDisclosureChevron: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    placeholderRowLeading
                        .frame(maxWidth: .infinity, alignment: .leading)
                    YabaIconView(bundleKey: "arrow-right-01")
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(nullModelPresentableColor.getUIColor())
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var placeholderRowLeading: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(nullModelPresentableColor.getUIColor().opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    YabaIconView(bundleKey: "bookmark-02")
                        .scaledToFit()
                        .foregroundStyle(nullModelPresentableColor.getUIColor())
                        .frame(width: 32, height: 32)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Select Bookmark Picker Prompt")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
    }
}
