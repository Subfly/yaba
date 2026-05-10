//
//  CSVDocmarkPaginationToolbar.swift
//  YABA
//
//  Floating paging chrome — mirrors ``LinkmarkReaderFloatingToolbar`` / ``NotemarkEditorFloatingToolbar``.
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
        GlassEffectContainer(spacing: 18) {
            controlsRow()
        }
        .glassEffect(.regular.interactive())
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func controlsRow() -> some View {
        let last = Swift.max(totalPages, 1)
        HStack(spacing: 6) {
            Button {
                onPrevious()
            } label: {
                toolbarGlyphButton("previous")
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }

            Button {
                onNext()
            } label: {
                toolbarGlyphButton("next")
            }
            .buttonStyle(.plain)
            .disabled(currentPage >= last)
        }
    }

    private func toolbarGlyphButton(_ bundleKey: String) -> some View {
        YabaIconView(bundleKey: bundleKey)
            .foregroundStyle(folderAccent)
            .frame(width: 22, height: 22)
            .padding()
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
