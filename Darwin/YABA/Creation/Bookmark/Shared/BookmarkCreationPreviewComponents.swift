//
//  BookmarkCreationPreviewComponents.swift
//  YABA
//

import SwiftUI
import UIKit

enum BookmarkCreationPreviewAppearanceMapping {
    static func previewContentAppearance(
        bookmarkAppearance: BookmarkAppearance,
        cardImageSizing: CardImageSizing
    ) -> PreviewContentAppearance {
        switch bookmarkAppearance {
        case .list: .list
        case .card: cardImageSizing == .big ? .cardBigImage : .cardSmallImage
        case .grid: .grid
        }
    }
}

struct BookmarkCreationLeadingFieldIcon: View {
    let bundleKey: String
    let mainTint: Color

    var body: some View {
        YabaIconView(bundleKey: bundleKey)
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(mainTint)
    }
}

struct BookmarkCreationPreviewHeader: View {
    @Binding var previewContentAppearance: PreviewContentAppearance
    let mainTint: Color
    var previewSectionIconBundleKey: String = "image-03"

    var body: some View {
        HStack {
            Label {
                Text("Preview")
            } icon: {
                YabaIconView(bundleKey: previewSectionIconBundleKey)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            }
            Spacer()
            Button {
                withAnimation {
                    switch previewContentAppearance {
                    case .list:
                        previewContentAppearance = .cardSmallImage
                    case .cardSmallImage:
                        previewContentAppearance = .cardBigImage
                    case .cardBigImage:
                        previewContentAppearance = .grid
                    case .grid:
                        previewContentAppearance = .list
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    if previewContentAppearance == .cardSmallImage ||
                        previewContentAppearance == .cardBigImage {
                        Label {
                            Text(ContentAppearance.card.getUITitle())
                                .textCase(.none)
                        } icon: {
                            YabaIconView(bundleKey: ContentAppearance.card.getUIIconName())
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                    }
                    Label {
                        Text(previewContentAppearance.getUITitle())
                            .textCase(.none)
                    } icon: {
                        YabaIconView(bundleKey: previewContentAppearance.getUIIconName())
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(mainTint)
        }
    }
}

// MARK: - Bookmark preview card (creation forms)

/// Shared preview layout across docmark/link/media/note creation flows.
/// Pass optional **`imageData`** (`nil` for icon-only previews). Preserve **`bigCardImageHeight`** (`180` vs `160` for link/notemark).
struct BookmarkCreationBookmarkPreviewContent: View {
    let previewContentAppearance: PreviewContentAppearance
    let imageData: Data?
    let fallbackIcon: String
    let mainTint: Color
    let label: String
    let bookmarkDescription: String
    var bigCardImageHeight: CGFloat = 180

    var body: some View {
        switch previewContentAppearance {
        case .list:
            HStack(alignment: .center, spacing: 12) {
                thumbnail(width: 56, height: 56)
                    .animation(.smooth, value: imageData)
                VStack(alignment: .leading, spacing: 4) {
                    headlineText(lineLimit: 1)
                    descriptionText(lineLimit: 2, alignment: .leading)
                }
            }
        case .cardSmallImage:
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    thumbnail(width: 56, height: 56)
                        .animation(.smooth, value: imageData)
                    headlineText(lineLimit: 2)
                    Spacer(minLength: 0)
                }
                descriptionText(lineLimit: 4, alignment: .leading)
            }
        case .cardBigImage:
            VStack(alignment: .leading, spacing: 10) {
                thumbnail(width: nil, height: bigCardImageHeight)
                    .animation(.smooth, value: imageData)
                headlineText(lineLimit: nil)
                descriptionText(lineLimit: 3, alignment: .leading)
            }
        case .grid:
            HStack {
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    thumbnail(width: 200, height: 200)
                        .animation(.smooth, value: imageData)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            headlineText(lineLimit: 2, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                        descriptionText(lineLimit: 2, alignment: .leading)
                    }
                    .padding()
                }
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.thinMaterial)
                }
                .frame(width: 200)
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(width: CGFloat?, height: CGFloat) -> some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(mainTint.opacity(0.25))
                .frame(width: width, height: height)
                .overlay {
                    YabaIconView(bundleKey: fallbackIcon)
                        .frame(width: 28, height: 28)
                        .foregroundStyle(mainTint)
                }
        }
    }

    @ViewBuilder
    private func headlineText(lineLimit: Int?, alignment: TextAlignment = .leading) -> some View {
        Group {
            if label.isEmpty {
                Text("Bookmark Title Placeholder")
                    .font(.headline)
            } else {
                Text(label)
                    .font(.headline)
                    .animation(.smooth, value: label)
            }
        }
        .modifier(OptionalLineLimitModifier(lineLimit: lineLimit))
        .multilineTextAlignment(alignment)
    }

    @ViewBuilder
    private func descriptionText(lineLimit: Int, alignment: TextAlignment) -> some View {
        Group {
            if bookmarkDescription.isEmpty {
                Text("Bookmark Description Placeholder")
                    .foregroundStyle(.secondary)
            } else {
                Text(bookmarkDescription)
                    .foregroundStyle(.secondary)
                    .animation(.smooth, value: bookmarkDescription)
            }
        }
        .lineLimit(lineLimit)
        .multilineTextAlignment(alignment)
    }

    private struct OptionalLineLimitModifier: ViewModifier {
        let lineLimit: Int?

        func body(content: Content) -> some View {
            if let lineLimit {
                content.lineLimit(lineLimit)
            } else {
                content
            }
        }
    }
}
