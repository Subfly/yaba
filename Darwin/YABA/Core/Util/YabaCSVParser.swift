//
//  YabaCSVParser.swift
//  YABA
//
//  CSV parsing via SwiftCSV (https://github.com/swiftcsv/SwiftCSV). Kept in the app target because
//  SwiftCSV is linked only on the main YABA target (not extensions that compile YABACore).
//

import Foundation
import SwiftCSV

/// Thin helpers around [SwiftCSV](https://github.com/swiftcsv/SwiftCSV) for docmark CSV preview and paging.
public enum YabaCSVParser {
    /// Hard ceiling for detail preview (see product copy in ``CSVDocmarkDetailView``).
    public static let maxIndexedLogicalCsvRecordsForPreview = 400_000

    private static let utf8BOM = "\u{FEFF}"

    /// Same idea as SwiftCSV’s prefix sniff — keep a bounded prefix for performance.
    public static func sniffDelimiter(prefixOf full: String) -> Character {
        let prefix = cappedString(full, maxChars: 8192)
        return CSVDelimiter.guessed(string: prefix).rawValue
    }

    /// Parses CSV from UTF‑8 bytes (lossy-safe decode). Returns `[]` on parse failure.
    public static func parseDelimited(utf8Payload: Data) -> [[String]] {
        guard !utf8Payload.isEmpty else { return [] }
        let text = decodeUtf8(csvBytes: utf8Payload)
        guard !text.isEmpty else { return [] }
        let delimiter = CSVDelimiter.guessed(string: text)
        return parseSwiftCSV(text: text, delimiter: delimiter)
    }

    public static func parse(csv text: String, delimiter: Character) -> [[String]] {
        guard !text.isEmpty else { return [] }
        return parseSwiftCSV(text: text, delimiter: CSVDelimiter(unicodeScalarLiteral: delimiter))
    }

    // MARK: - Docmark paging (no full in-memory `[[String]]` for the whole file)

    /// Outcome of building a paging preview — **SwiftCSV** counts body rows without retaining `[Range<String.Index>]`.
    public enum PagingSkeletonOutcome: Sendable {
        case outline(csvText: String, delimiter: Character, headerRow: [String], bodyRowCount: Int)
        case tooManyRows
        case emptyOrInvalid
    }

    public static func makePagingSkeleton(utf8Payload: Data) -> PagingSkeletonOutcome {
        guard !utf8Payload.isEmpty else { return .emptyOrInvalid }
        let csvText = decodeUtf8(csvBytes: utf8Payload)
        guard !csvText.isEmpty else { return .emptyOrInvalid }

        let delimiter = CSVDelimiter.guessed(string: csvText)

        let headerRow: [String]
        do {
            let headerOnly = try CSV<Enumerated>(string: csvText, delimiter: delimiter, loadColumns: false, rowLimit: 0)
            headerRow = headerOnly.header
        } catch {
            return .emptyOrInvalid
        }

        let bodyCount: Int
        do {
            bodyCount = try countBodyRows(csvText: csvText, delimiter: delimiter)
        } catch {
            return .emptyOrInvalid
        }

        if bodyCount > maxIndexedLogicalCsvRecordsForPreview {
            return .tooManyRows
        }

        guard hasPrintableCells(header: headerRow, bodyRowCount: bodyCount) else { return .emptyOrInvalid }
        return .outline(csvText: csvText, delimiter: delimiter.rawValue, headerRow: headerRow, bodyRowCount: bodyCount)
    }

    public static func pageRows(
        csvText: String,
        delimiter: Character,
        headerRow: [String],
        bodyRowCount: Int,
        pageIndex: Int,
        rowsPerPage: Int
    ) -> [[String]] {
        let swiftDelim = CSVDelimiter(unicodeScalarLiteral: delimiter)
        let perPage = Swift.max(1, rowsPerPage)
        let baseWidth = heuristicWidth(
            headerRow: headerRow,
            bodyRowCount: bodyRowCount,
            csvText: csvText,
            delimiter: swiftDelim
        )
        let paddedHeader = normalizeRow(headerRow, to: baseWidth)

        if bodyRowCount <= 0 {
            return alignColumnWidths([paddedHeader, Array(repeating: "", count: baseWidth)])
        }

        let totalPages = Self.pageCount(bodyRowCount: bodyRowCount, rowsPerPage: perPage)
        let clampedPage = Swift.min(Swift.max(0, pageIndex), Swift.max(totalPages - 1, 0))
        let lo = clampedPage * perPage
        let hi = Swift.min(lo + perPage, bodyRowCount)
        guard lo < hi else {
            return alignColumnWidths([paddedHeader, Array(repeating: "", count: baseWidth)])
        }

        var body: [[String]] = []
        do {
            let csv = try CSV<Enumerated>(string: csvText, delimiter: swiftDelim, loadColumns: false, rowLimit: 0)
            try csv.enumerateAsArray(startAt: 1 + lo, rowLimit: hi - lo) { fields in
                body.append(normalizeRow(fields, to: baseWidth))
            }
        } catch {
            return alignColumnWidths([paddedHeader, Array(repeating: "", count: baseWidth)])
        }

        return alignColumnWidths([paddedHeader] + body)
    }

    public static func pageCount(bodyRowCount: Int, rowsPerPage: Int) -> Int {
        let per = Swift.max(1, rowsPerPage)
        if bodyRowCount <= 0 { return 1 }
        return (bodyRowCount + per - 1) / per
    }

    public static func alignColumnWidths(_ rows: [[String]]) -> [[String]] {
        guard let maxWidth = rows.map(\.count).max(), maxWidth > 0 else {
            return rows
        }
        return rows.map { row in normalizeRow(row, to: maxWidth) }
    }

    // MARK: - Private

    private static func decodeUtf8(csvBytes: Data) -> String {
        var s = String(data: csvBytes, encoding: .utf8) ?? String(decoding: csvBytes, as: UTF8.self)
        if s.hasPrefix(utf8BOM) {
            s.removeFirst()
        }
        return s
    }

    private static func cappedString(_ s: String, maxChars: Int) -> String {
        guard !s.isEmpty else { return s }
        guard s.count > maxChars else { return s }
        let idx = s.index(s.startIndex, offsetBy: maxChars)
        return String(s[..<idx])
    }

    private static func parseSwiftCSV(text: String, delimiter: CSVDelimiter) -> [[String]] {
        do {
            let csv = try CSV<Enumerated>(string: text, delimiter: delimiter, loadColumns: false)
            return [csv.header] + csv.rows
        } catch {
            return []
        }
    }

    /// Counts **data** rows (excludes header line). Uses one streamed pass; throws on parse errors.
    private static func countBodyRows(csvText: String, delimiter: CSVDelimiter) throws -> Int {
        let csv = try CSV<Enumerated>(string: csvText, delimiter: delimiter, loadColumns: false, rowLimit: 0)
        var n = 0
        try csv.enumerateAsArray(
            startAt: 1,
            rowLimit: maxIndexedLogicalCsvRecordsForPreview + 1
        ) { _ in
            n += 1
        }
        return n
    }

    private static func heuristicWidth(headerRow: [String], bodyRowCount: Int, csvText: String, delimiter: CSVDelimiter) -> Int {
        if !headerRow.isEmpty { return Swift.max(1, headerRow.count) }
        guard bodyRowCount > 0 else { return 1 }
        var firstRow: [String] = []
        do {
            let csv = try CSV<Enumerated>(string: csvText, delimiter: delimiter, loadColumns: false, rowLimit: 0)
            try csv.enumerateAsArray(startAt: 1, rowLimit: 1) { fields in
                firstRow = fields
            }
        } catch {
            return 1
        }
        return Swift.max(1, firstRow.count)
    }

    private static func normalizeRow(_ row: [String], to width: Int) -> [String] {
        if row.count == width { return row }
        if row.count < width { return row + Array(repeating: "", count: width - row.count) }
        return Array(row.prefix(width))
    }

    private static func hasPrintableCells(header: [String], bodyRowCount: Int) -> Bool {
        let headerPrintable = header.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if headerPrintable { return true }
        return bodyRowCount > 0
    }
}
