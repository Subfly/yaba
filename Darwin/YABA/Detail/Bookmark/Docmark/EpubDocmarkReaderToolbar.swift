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
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 14) {
                    controlsRow(padIos26Glyphs: true)
                }
                .glassEffect(.regular.interactive())
            } else {
                controlsRow(padIos26Glyphs: false)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func controlsRow(padIos26Glyphs: Bool) -> some View {
        let spacing: CGFloat = padIos26Glyphs ? 10 : 12
        HStack(spacing: spacing) {
            Button(action: onPrevious) {
                toolbarGlyphButton("previous", pad: padIos26Glyphs)
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
                menuLabelIcon("colors", padLabels: padIos26Glyphs, color: folderAccent)
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
                menuLabelIcon("text-square", padLabels: padIos26Glyphs, color: folderAccent)
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
                menuLabelIcon("cursor-text", padLabels: padIos26Glyphs, color: folderAccent)
            }

            Button(action: onNext) {
                toolbarGlyphButton("next", pad: padIos26Glyphs)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func menuLabelIcon(
        _ icon: String,
        padLabels: Bool,
        color: Color
    ) -> some View {
        if padLabels {
            toolbarGlyph(icon, color: color).padding()
        } else {
            toolbarGlyph(icon, color: color)
        }
    }

    private func toolbarGlyph(_ icon: String, color: Color) -> some View {
        YabaIconView(bundleKey: icon)
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
    }

    private func toolbarGlyphButton(_ bundleKey: String, pad: Bool) -> some View {
        Group {
            if pad {
                YabaIconView(bundleKey: bundleKey)
                    .foregroundStyle(folderAccent)
                    .frame(width: 22, height: 22)
                    .padding()
            } else {
                YabaIconView(bundleKey: bundleKey)
                    .foregroundStyle(folderAccent)
                    .frame(width: 22, height: 22)
            }
        }
    }
}
