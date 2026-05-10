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
        .glassEffect(.regular.interactive())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 24)
        .animation(.smooth, value: isVisible)
    }

    @ViewBuilder
    private func toolbarMenus() -> some View {
        HStack(spacing: 0) {
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
                menuLabelIcon("colors", color: folderAccent)
            }
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
                menuLabelIcon("text-square", color: folderAccent)
            }
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
                menuLabelIcon("cursor-text", color: folderAccent)
            }
        }
    }

    @ViewBuilder
    private func menuLabelIcon(
        _ icon: String,
        color: Color
    ) -> some View {
        toolbarGlyph(icon, color: color).padding()
    }

    private func toolbarGlyph(_ icon: String, color: Color) -> some View {
        YabaIconView(bundleKey: icon)
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
    }
}
