//
//  CSVDocmarkPaginationToolbar.swift
//  YABA
//
//  CSV page jump control for the navigation toolbar (replacing the former floating pager).
//

import Observation
import SwiftUI

@Observable
final class CSVDocmarkPagingCoordinator {
    private(set) var showsPageMenu = false
    private(set) var currentPage = 1
    private(set) var totalPages = 1
    var onSelectPage: (Int) -> Void = { _ in }

    func bind(isReady: Bool, pageZero: Int, totalPages: Int, onSelect: @escaping (Int) -> Void) {
        onSelectPage = onSelect
        guard isReady else {
            showsPageMenu = false
            return
        }
        showsPageMenu = true
        let last = Swift.max(1, totalPages)
        self.totalPages = last
        currentPage = Swift.min(Swift.max(1, pageZero + 1), last)
    }
}

struct CSVDocmarkPageJumpMenu: View {
    let folderAccent: Color
    let currentPage: Int
    let totalPages: Int
    let onSelectPage: (Int) -> Void

    /// Cap building an enormous SwiftUI ``Menu``.
    private static let menuPageCap = 400

    var body: some View {
        let last = Swift.max(totalPages, 1)
        Menu {
            jumpMenuContent(totalPages: last)
        } label: {
            Text("\(currentPage)")
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(folderAccent)
                .contentShape(.circle)
        }
    }

    @ViewBuilder
    private func jumpMenuContent(totalPages: Int) -> some View {
        if totalPages <= Self.menuPageCap {
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
