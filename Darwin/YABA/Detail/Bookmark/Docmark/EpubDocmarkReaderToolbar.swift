//
//  EpubDocmarkReaderToolbar.swift
//  YABA
//
//

import SwiftUI

struct EpubDocmarkReaderToolbar: View {
    let folderAccent: Color
    let readerTheme: ReaderTheme
    let readerFontSize: ReaderFontSize
    let readerLineHeight: ReaderLineHeight
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSelectTheme: (ReaderTheme) -> Void
    let onSelectFontSize: (ReaderFontSize) -> Void
    let onSelectLineHeight: (ReaderLineHeight) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            controlsRow()
        }
        .bookmarkFloatingReaderGlassEffectInteractive()
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func controlsRow() -> some View {
        HStack(spacing: 10) {
            Button(action: onPrevious) {
                BookmarkReaderFloatingToolbarGlyph.paginationNavTrigger(bundleKey: "previous", accent: folderAccent)
            }
            .buttonStyle(.plain)

            ReaderToolbarThemeMenu(
                folderAccent: folderAccent,
                readerTheme: readerTheme,
                onSelectTheme: onSelectTheme
            )

            ReaderToolbarFontMenu(
                folderAccent: folderAccent,
                readerFontSize: readerFontSize,
                onSelectFontSize: onSelectFontSize
            )

            ReaderToolbarLineHeightMenu(
                folderAccent: folderAccent,
                readerLineHeight: readerLineHeight,
                onSelectLineHeight: onSelectLineHeight
            )

            Button(action: onNext) {
                BookmarkReaderFloatingToolbarGlyph.paginationNavTrigger(bundleKey: "next", accent: folderAccent)
            }
            .buttonStyle(.plain)
        }
    }
}
