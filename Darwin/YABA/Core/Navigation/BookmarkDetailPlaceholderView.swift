//
//  BookmarkDetailPlaceholderView.swift
//  YABA
//
//  Empty third column when no bookmark is selected in split navigation.
//

import SwiftUI

struct BookmarkDetailPlaceholderView: View {
    var body: some View {
        ZStack {
            AnimatedGradient(color: .accentColor)
            ContentUnavailableView {
                Label {
                    Text("YABA")
                } icon: {
                    YabaIconView(bundleKey: "bookmark-02")
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                }
            } description: {
                Text("YABA Description")
            }
        }
    }
}
