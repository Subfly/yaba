//
//  CSVDocmarkPaginationToolbar.swift
//  YABA
//
//  Floating paging chrome — mirrors ``LinkmarkReaderFloatingToolbar`` / ``NotemarkEditorFloatingToolbar`` glass / capsule fallbacks.
//

import SwiftUI

struct CSVDocmarkPaginationToolbar: View {
    let folderAccent: Color
    let currentPage: Int
    let totalPages: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSelectPage: (Int) -> Void

    /// Cap building an enormous SwiftUI ``Menu``.
    private static let menuPageCap = 400

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 18) {
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
        let last = Swift.max(totalPages, 1)
        HStack(spacing: padIos26Glyphs ? 6 : 10) {
            Button {
                onPrevious()
            } label: {
                toolbarGlyphButton("previous", pad: padIos26Glyphs)
            }
            .buttonStyle(.plain)
            .disabled(currentPage <= 1)

            Menu {
                jumpMenuContent(totalPages: last)
            } label: {
                Text("\(currentPage)")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(folderAccent)
                    .padding(.horizontal, padIos26Glyphs ? 14 : 10)
                    .padding(.vertical, padIos26Glyphs ? 10 : 4)
                    .contentShape(Rectangle())
            }

            Button {
                onNext()
            } label: {
                toolbarGlyphButton("next", pad: padIos26Glyphs)
            }
            .buttonStyle(.plain)
            .disabled(currentPage >= last)
        }
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

    @ViewBuilder
    private func jumpMenuContent(totalPages: Int) -> some View {
        if totalPages <= Self.menuPageCap {
            // Menus tend to paint last-built items at the top — reverse so page 1 appears first when reading down.
            ForEach(Array((1 ... totalPages).reversed()), id: \.self) { page in
                Button {
                    onSelectPage(page)
                } label: {
                    pageMenuRow(page, isCurrent: page == currentPage)
                }
            }
        } else {
            let brackets = Self.pageIntervals(totalPages)
            ForEach(brackets.reversed(), id: \.self) { interval in
                Menu(intervalLabel(interval)) {
                    ForEach(Array(interval).reversed(), id: \.self) { page in
                        Button {
                            onSelectPage(page)
                        } label: {
                            pageMenuRow(page, isCurrent: page == currentPage)
                        }
                    }
                }
            }
        }
    }

    private func pageMenuRow(_ page: Int, isCurrent: Bool) -> some View {
        HStack {
            if isCurrent {
                Image(systemName: "checkmark")
            }
            Text("Page Label \(page)")
        }
    }

    private func intervalLabel(_ interval: ClosedRange<Int>) -> String {
        if interval.lowerBound == interval.upperBound {
            "\(interval.lowerBound)"
        } else {
            "\(interval.lowerBound)–\(interval.upperBound)"
        }
    }

    private static func pageIntervals(_ total: Int, chunkSize: Int = 100) -> [ClosedRange<Int>] {
        guard total > 0 else { return [] }
        var out: [ClosedRange<Int>] = []
        var n = 1
        while n <= total {
            let hi = Swift.min(n + chunkSize - 1, total)
            out.append(n ... hi)
            n = hi + 1
        }
        return out
    }
}
