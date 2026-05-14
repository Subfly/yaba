//
//  BookmarkDetailReaderChrome.swift
//  YABA
//

import SwiftUI

// MARK: - Reader surface (theme tint + brightness)

enum BookmarkDetailReaderChrome {
    static func readerSurfaceBackground(readerTheme: ReaderTheme) -> Color {
        if readerTheme == .sepia {
            Color(red: 0.98, green: 0.95, blue: 0.88)
        } else {
            Color(.systemBackground)
        }
    }

    /// Maps reader theme selections to SwiftUI `ColorScheme`.
    static func preferredColorScheme(
        readerTheme: ReaderTheme,
        userInterfaceColorScheme: ColorScheme
    ) -> ColorScheme {
        switch readerTheme {
        case .light, .sepia:
            .light
        case .dark:
            .dark
        case .system:
            userInterfaceColorScheme
        }
    }

    /// Standard “reader not available” empty state (`Reader Not Available` keys).
    @ViewBuilder
    static func readerUnavailablePlaceholder(iconBundleKey: String, tint: Color) -> some View {
        ContentUnavailableView {
            Label {
                Text("Reader Not Available Title")
            } icon: {
                YabaIconView(bundleKey: iconBundleKey)
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(tint)
            }
        } description: {
            Text("Reader Not Available Description")
        }
    }

    /// Link detail empty-readable body preserves iPad-aware horizontal inset on the footer copy.
    @ViewBuilder
    static func linkReaderUnavailablePlaceholder(tint: Color) -> some View {
        ContentUnavailableView {
            Label {
                Text("Reader Not Available Title")
                    .padding(.bottom)
            } icon: {
                YabaIconView(bundleKey: "cancel-square")
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(tint)
                    .padding(.top)
            }
        } description: {
            Text("Reader Not Available Description")
                .padding(
                    .horizontal,
                    UIDevice.current.userInterfaceIdiom == .pad ? 52 : 0
                )
        }
    }
}

// MARK: - Floating glass toolbar shell

extension View {
    /// Shared liquid-glass wrapping for bookmark reader/editor floating chrome.
    func bookmarkFloatingReaderGlassEffectInteractive() -> some View {
        glassEffect(.regular.interactive())
    }
}
