//
//  CSVDocmarkDetailView.swift
//  YABA
//
//

import SwiftUI
import UIKit

private struct IndexedCSVRow: Identifiable {
    let id: Int
    let cells: [String]
}

/// Parsed outline + indexes only (no megabyte-long `[[String]]` retained). Built off-main.
private final class CSVDetailOutline: @unchecked Sendable {
    static let rowsPerPage = 100

    let csvText: String
    let delimiter: Character
    let headerRow: [String]
    let bodyRowCount: Int

    private init(csvText: String, delimiter: Character, headerRow: [String], bodyRowCount: Int) {
        self.csvText = csvText
        self.delimiter = delimiter
        self.headerRow = headerRow
        self.bodyRowCount = bodyRowCount
    }

    enum BuildOutcome {
        case success(CSVDetailOutline)
        case tooManyLogicalRows
        case emptyOrUnparseable
    }

    static func build(csvBytes: Data) -> BuildOutcome {
        guard !csvBytes.isEmpty else { return .emptyOrUnparseable }

        switch YabaCSVParser.makePagingSkeleton(utf8Payload: csvBytes) {
        case .tooManyRows:
            return .tooManyLogicalRows
        case .emptyOrInvalid:
            return .emptyOrUnparseable
        case let .outline(csvText, delimiter, headerRow, bodyRowCount):
            let outline = CSVDetailOutline(
                csvText: csvText,
                delimiter: delimiter,
                headerRow: headerRow,
                bodyRowCount: bodyRowCount
            )
            return .success(outline)
        }
    }

    func slice(pageZeroIndexed: Int) -> [[String]] {
        YabaCSVParser.pageRows(
            csvText: csvText,
            delimiter: delimiter,
            headerRow: headerRow,
            bodyRowCount: bodyRowCount,
            pageIndex: pageZeroIndexed,
            rowsPerPage: Self.rowsPerPage
        )
    }

    var totalPages: Int {
        YabaCSVParser.pageCount(bodyRowCount: bodyRowCount, rowsPerPage: Self.rowsPerPage)
    }
}

struct CSVDocmarkDetailView: View {
    let bookmarkId: String
    let csvBytes: Data
    let folderTint: Color

#if os(iOS)
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
#endif

    /// On compact width, ``Table`` effectively surfaces a single column — we show every CSV field stacked in that column.
    private var isCsvTableCompact: Bool {
#if os(iOS)
        horizontalSizeClass == .compact
#else
        false
#endif
    }

    private enum Phase {
        case loading
        case ready
        case tooLarge
        case tooManyRows
        case unavailable
    }

    @State
    private var phase: Phase = .loading

    @State
    private var outline: CSVDetailOutline?

    @State
    private var pageZero = 0

    @State
    private var displayedRows: [[String]] = []

    private static let maxCsvBytes = 50 * 1024 * 1024

    var body: some View {
        csvBody
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if phase == .ready, outline != nil {
                    HStack {
                        Spacer(minLength: 0)
                        CSVDocmarkPaginationToolbar(
                            folderAccent: folderTint,
                            currentPage: currentPageDisplay,
                            totalPages: outline?.totalPages ?? 1,
                            onPrevious: { goPreviousPage() },
                            onNext: { goNextPage() },
                            onSelectPage: { selectPage(oneBased: $0) }
                        )
                        .allowsHitTesting(true)
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, 8)
                }
            }
            .task(id: "\(bookmarkId)-\(csvBytes.count)") {
                await load()
            }
    }

    @ViewBuilder
    private var csvBody: some View {
        switch phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .ready:
            if displayedRows.isEmpty || !hasPrintable(displayedRows) {
                emptyStateView
            } else {
                docmarkCSVTable(displayedRows)
                    .foregroundStyle(Color.primary.opacity(0.95))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        case .tooLarge:
            ContentUnavailableView {
                Label {
                    Text("Docmark Csv Too Large Label")
                } icon: {
                    YabaIconView(bundleKey: "sad-01")
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundStyle(folderTint)
                }
            } description: {
                Text("Docmark Csv Too Large Description")
            }
        case .tooManyRows:
            ContentUnavailableView {
                Label {
                    Text("Docmark Csv Too Large Label")
                } icon: {
                    YabaIconView(bundleKey: "sad-01")
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundStyle(folderTint)
                }
            } description: {
                Text("Docmark Csv Too Many Rows Description \(YabaCSVParser.maxIndexedLogicalCsvRecordsForPreview)")
            }
        case .unavailable:
            emptyStateView
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label {
                Text("Reader Not Available Title")
            } icon: {
                YabaIconView(bundleKey: "csv-02")
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(folderTint)
            }
        } description: {
            Text("Reader Not Available Description")
        }
        .padding()
    }
    
    // MARK: — `Table` (iPhone + iPad)

    /// Uses SwiftUI `Table`. On compact horizontal size class, one column shows **every** field as “header → value”; on regular width, all CSV columns are separate table columns.
    @ViewBuilder
    private func docmarkCSVTable(_ rows: [[String]]) -> some View {
        if let widths = rows.first?.count, widths > 0 {
            let bodyRows = rows.dropFirst().enumerated().map { IndexedCSVRow(id: $0.offset, cells: $0.element) }
            let displayRows = bodyRows.isEmpty
                ? [IndexedCSVRow(id: 0, cells: Array(repeating: "", count: widths))]
                : bodyRows
            let headerCells = rows[0]

            if isCsvTableCompact {
                Table(displayRows) {
                    TableColumn("Csv Docmark Compact Table Column Title") { row in
                        compactCsvRowDetail(headerCells: headerCells, columnCount: widths, row: row)
                    }
                }
            } else {
                Table(displayRows) {
                    TableColumnForEach(Array(0 ..< widths), id: \.self) { colIdx in
                        TableColumn(
                            columnHeading(rows[0][colIdx], columnIndex: colIdx)
                        ) { row in
                            Text(at(row.cells, colIdx))
                                .font(.footnote.monospaced())
                                .multilineTextAlignment(.leading)
                                .lineLimit(6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .width(min: 110, ideal: 134)
                    }
                }
            }
        } else {
            emptyStateView
        }
    }

    /// Compact `Table` cell: stacks labeled fields so all CSV columns are visible in one swipeable column.
    @ViewBuilder
    private func compactCsvRowDetail(headerCells: [String], columnCount: Int, row: IndexedCSVRow) -> some View {
        let fieldCount = min(columnCount, headerCells.count, row.cells.count)
        Button {
            copyCsvRowToClipboard(headerCells: headerCells, row: row, columnCount: fieldCount)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0 ..< fieldCount, id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 4) {
                        let heading = columnHeading(headerCells[idx], columnIndex: idx)
                        if !heading.isEmpty {
                            Text(heading)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text(at(row.cells, idx))
                            .font(.footnote.monospaced())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, idx < fieldCount - 1 ? 12 : 0)
                }
            }.padding(.vertical, 4)
        }.buttonStyle(.plain)
    }
    
    private var currentPageDisplay: Int {
        min(max(1, pageZero + 1), max(1, outline?.totalPages ?? 1))
    }

    private func goPreviousPage() {
        guard pageZero > 0 else { return }
        pageZero -= 1
        applyCurrentPageSlice()
    }

    private func goNextPage() {
        guard let outline else { return }
        guard pageZero + 1 < outline.totalPages else { return }
        pageZero += 1
        applyCurrentPageSlice()
    }

    private func selectPage(oneBased: Int) {
        guard let outline else { return }
        let zero = max(0, min(oneBased - 1, outline.totalPages - 1))
        pageZero = zero
        applyCurrentPageSlice()
    }

    private func load() async {
        outline = nil
        displayedRows = []
        pageZero = 0

        guard !csvBytes.isEmpty else {
            phase = .unavailable
            return
        }
        guard csvBytes.count <= Self.maxCsvBytes else {
            phase = .tooLarge
            return
        }

        phase = .loading

        let boxed = await Task.detached(priority: .utility) {
            CSVDetailOutline.build(csvBytes: csvBytes)
        }.value

        let boxedOutline: CSVDetailOutline
        switch boxed {
        case let .success(outline):
            boxedOutline = outline
        case .tooManyLogicalRows:
            phase = .tooManyRows
            return
        case .emptyOrUnparseable:
            phase = .unavailable
            return
        }

        let starter = boxedOutline.slice(pageZeroIndexed: 0)
        guard hasPrintable(starter) else {
            phase = .unavailable
            return
        }

        outline = boxedOutline
        displayedRows = starter
        phase = .ready
    }

    private func applyCurrentPageSlice() {
        guard let outline else { return }
        let maxP = max(0, outline.totalPages - 1)
        let idx = min(max(0, pageZero), maxP)
        if idx != pageZero {
            pageZero = idx
        }
        displayedRows = outline.slice(pageZeroIndexed: idx)
    }

    private func copyCsvRowToClipboard(headerCells: [String], row: IndexedCSVRow, columnCount: Int) {
        let payload = clipboardStringForCsvRow(
            headers: headerCells,
            cells: row.cells,
            columnCount: columnCount
        )
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UIPasteboard.general.string = payload
        CoreToastManager.shared.show(
            message: LocalizedStringKey("Bookmark CSV Row Copy To Clipboard Success Message"),
            iconType: .success,
            duration: .short
        )
    }

    private func at(_ cells: [String], _ index: Int) -> String {
        guard index >= 0, index < cells.count else { return "" }
        return cells[index]
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    private func columnHeading(_ raw: String, columnIndex _: Int) -> String {
        let sanitized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        if sanitized.isEmpty {
            return ""
        }
        if sanitized.count <= 48 {
            return sanitized
        }
        return String(sanitized.prefix(48)) + "…"
    }

    private func hasPrintable(_ rows: [[String]]) -> Bool {
        guard !rows.isEmpty else {
            return false
        }
        return rows.flatMap(\.self)
            .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// One line per column: **`title: value`**, or **`value` only** when the CSV header cell is empty.
    private func clipboardStringForCsvRow(headers: [String], cells: [String], columnCount: Int) -> String {
        let n = min(columnCount, headers.count, cells.count)
        guard n > 0 else { return "" }
        return (0 ..< n)
            .map { idx -> String in
                let title = columnHeading(headers[idx], columnIndex: idx)
                let value = at(cells, idx)
                if title.isEmpty {
                    return value
                }
                return "\(title): \(value)"
            }
            .joined(separator: "\n")
    }
}
