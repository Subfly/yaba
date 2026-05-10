//
//  Created by Ali Taha on 20.04.2026.
//

import SwiftUI

// MARK: - Reader floating toolbar

struct LinkmarkReaderFloatingToolbar: View {
    let folderAccent: Color
    let isVisible: Bool
    let readerTheme: ReaderTheme
    let readerFontSize: ReaderFontSize
    let readerLineHeight: ReaderLineHeight
    let onSelectTheme: (ReaderTheme) -> Void
    let onSelectFontSize: (ReaderFontSize) -> Void
    let onSelectLineHeight: (ReaderLineHeight) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 30) {
            toolbarMenus()
        }
        .bookmarkFloatingReaderGlassEffectInteractive()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .animation(.smooth, value: isVisible)
    }

    @ViewBuilder
    private func toolbarMenus() -> some View {
        HStack(spacing: 0) {
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
        }
    }
}
