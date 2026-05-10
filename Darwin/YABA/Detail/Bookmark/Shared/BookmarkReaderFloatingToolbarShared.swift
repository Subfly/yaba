//
//  BookmarkReaderFloatingToolbarShared.swift
//  YABA
//

import SwiftUI

// MARK: - Glyphs & menu triggers

enum BookmarkReaderFloatingToolbarGlyph {
    @ViewBuilder
    static func icon(bundleKey: String, accent: Color) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .foregroundStyle(accent)
            .frame(width: 22, height: 22)
    }

    /// Padded toolbar icon used as the visible `Menu` label.
    static func menuTrigger(bundleKey: String, accent: Color) -> some View {
        Self.icon(bundleKey: bundleKey, accent: accent).padding()
    }

    /// Label for previous/next glyph buttons matching EPUB / CSV pagination toolbars.
    static func paginationNavTrigger(bundleKey: String, accent: Color) -> some View {
        Self.icon(bundleKey: bundleKey, accent: accent).padding()
    }
}

// MARK: - Reader setting menus (theme / typography)

struct ReaderToolbarThemeMenu: View {
    let folderAccent: Color
    let readerTheme: ReaderTheme
    let onSelectTheme: (ReaderTheme) -> Void

    var body: some View {
        Menu {
            ForEach(ReaderTheme.allCases, id: \.self) { t in
                Button {
                    onSelectTheme(t)
                } label: {
                    HStack {
                        if readerTheme == t {
                            Image(systemName: "checkmark")
                        }
                        Text(t.getUITitle())
                    }
                }
            }
        } label: {
            BookmarkReaderFloatingToolbarGlyph.menuTrigger(bundleKey: "colors", accent: folderAccent)
        }
    }
}

struct ReaderToolbarFontMenu: View {
    let folderAccent: Color
    let readerFontSize: ReaderFontSize
    let onSelectFontSize: (ReaderFontSize) -> Void

    var body: some View {
        Menu {
            ForEach(ReaderFontSize.allCases, id: \.self) { f in
                Button {
                    onSelectFontSize(f)
                } label: {
                    HStack {
                        if readerFontSize == f {
                            Image(systemName: "checkmark")
                        }
                        Text(f.getUITitle())
                    }
                }
            }
        } label: {
            BookmarkReaderFloatingToolbarGlyph.menuTrigger(bundleKey: "text-square", accent: folderAccent)
        }
    }
}

struct ReaderToolbarLineHeightMenu: View {
    let folderAccent: Color
    let readerLineHeight: ReaderLineHeight
    let onSelectLineHeight: (ReaderLineHeight) -> Void

    var body: some View {
        Menu {
            ForEach(ReaderLineHeight.allCases, id: \.self) { lh in
                Button {
                    onSelectLineHeight(lh)
                } label: {
                    HStack {
                        if readerLineHeight == lh {
                            Image(systemName: "checkmark")
                        }
                        Text(lh.getUITitle())
                    }
                }
            }
        } label: {
            BookmarkReaderFloatingToolbarGlyph.menuTrigger(bundleKey: "cursor-text", accent: folderAccent)
        }
    }
}
