//
//  ImagemarkDetailView.swift
//  YABA
//

import SwiftUI

struct ImagemarkDetailView: View {
    let bookmark: YabaBookmark
    let folderTint: Color

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            if let uiImage = displayUIImage(for: bookmark) {
                ZoomablePannableView {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            } else {
                ContentUnavailableView {
                    Label {
                        Text("Bookmark Detail Image Error Title")
                    } icon: {
                        YabaIconView(bundleKey: "image-not-found-01")
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .foregroundStyle(folderTint)
                    }
                } description: {
                    Text("Reader Not Available Description")
                }
            }
        }
    }

    private func displayUIImage(for bm: YabaBookmark) -> UIImage? {
        let data = bm.mediaDetail?.originalData ?? bm.imagePayload?.bytes
        guard let data, !data.isEmpty else { return nil }
        return UIImage(data: data)
    }
}
