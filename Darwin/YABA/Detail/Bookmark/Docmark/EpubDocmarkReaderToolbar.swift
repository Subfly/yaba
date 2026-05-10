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
        .glassEffect(.regular.interactive())
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func controlsRow() -> some View {
        HStack(spacing: 10) {
            Button(action: onPrevious) {
                toolbarGlyphButton("previous")
            }
            .buttonStyle(.plain)

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

            Button(action: onNext) {
                toolbarGlyphButton("next")
            }
            .buttonStyle(.plain)
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

    private func toolbarGlyphButton(_ bundleKey: String) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .foregroundStyle(folderAccent)
            .frame(width: 22, height: 22)
            .padding()
    }
}
