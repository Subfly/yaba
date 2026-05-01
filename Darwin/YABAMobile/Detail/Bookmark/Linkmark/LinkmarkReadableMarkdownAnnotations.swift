//
//  LinkmarkReadableMarkdownAnnotations.swift
//  YABAMobile
//
//  Readable link annotations as Markdown directives (parity with preview WebView):
//  ::yaba-annotation{id="<uuid>" color="YELLOW"}quoted text::
//

import Foundation

enum LinkmarkReadableMarkdownAnnotations {
    enum AnnotationEditError: Error {
        case emptySelection
        case ambiguousSelection
        case selectionNotFound
    }

    /// Inserts a directive around exactly one occurrence of `selectedText`.
    static func insertDirective(
        markdown: String,
        selectedText: String,
        prefixText: String?,
        suffixText: String?,
        annotationId: String,
        color: YabaColor
    ) throws -> String {
        let quote = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty else { throw AnnotationEditError.emptySelection }

        let directives = parseDirectiveSpans(markdown)
        let ranges = occurrenceRanges(of: quote, in: markdown).filter { r in
            !directives.contains(where: { rangesOverlap($0.fullRange, r) })
        }

        let filtered = filterOccurrences(
            ranges,
            in: markdown,
            prefixText: prefixText,
            suffixText: suffixText
        )

        guard let target = filtered.singleOrNil else {
            throw filtered.isEmpty ? AnnotationEditError.selectionNotFound : AnnotationEditError.ambiguousSelection
        }

        let open = "::yaba-annotation{id=\"\(annotationId)\" color=\"\(colorToken(for: color))\"}"
        let close = "::"
        let wrapped = "\(open)\(quote)\(close)"

        var out = markdown
        out.replaceSubrange(target, with: wrapped)
        return out
    }

    /// Removes the directive with the given id, preserving inner text.
    static func removeDirective(markdown: String, annotationId: String) -> String {
        guard let span = parseDirectiveSpans(markdown).first(where: { $0.id == annotationId }) else {
            return markdown
        }
        var out = markdown
        out.replaceSubrange(span.fullRange, with: span.innerText)
        return out
    }

    /// Updates only the `color="..."` segment for an existing directive id.
    static func setDirectiveColor(markdown: String, annotationId: String, color: YabaColor) -> String {
        let token = colorToken(for: color)
        let spans = parseDirectiveSpans(markdown)
        guard let span = spans.first(where: { $0.id == annotationId }) else { return markdown }

        let headerPrefix = "::yaba-annotation{id=\"\(annotationId)\" color=\""

        guard let hdrRange = markdown.range(of: headerPrefix, range: span.fullRange) else {
            return markdown
        }

        let afterColorStart = hdrRange.upperBound
        guard let colorEnd = markdown[afterColorStart...].firstIndex(of: "\"") else {
            return markdown
        }

        var out = markdown
        out.replaceSubrange(afterColorStart ..< colorEnd, with: token)
        return out
    }

    // MARK: - Internals

    private struct DirectiveSpan {
        let id: String
        let fullRange: Range<String.Index>
        let innerText: String
    }

    private static func parseDirectiveSpans(_ markdown: String) -> [DirectiveSpan] {
        let pattern =
            #"::yaba-annotation\{id=\"([^\"]+)\"\s+color=\"([^\"]+)\"\}"#
                + #"([\s\S]*?)::"#

        guard let re = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let ns = markdown as NSString
        let full = NSRange(location: 0, length: ns.length)
        var out: [DirectiveSpan] = []

        re.enumerateMatches(in: markdown, options: [], range: full) { result, _, _ in
            guard let result, result.numberOfRanges >= 4,
                  let fullR = Range(result.range, in: markdown),
                  let idR = Range(result.range(at: 1), in: markdown),
                  let innerR = Range(result.range(at: 3), in: markdown)
            else {
                return
            }

            let id = String(markdown[idR])
            let inner = String(markdown[innerR])
            out.append(DirectiveSpan(id: id, fullRange: fullR, innerText: inner))
        }

        return out
    }

    private static func occurrenceRanges(of needle: String, in haystack: String) -> [Range<String.Index>] {
        guard !needle.isEmpty else { return [] }
        var ranges: [Range<String.Index>] = []
        var searchStart = haystack.startIndex
        while searchStart < haystack.endIndex,
              let r = haystack.range(of: needle, range: searchStart ..< haystack.endIndex)
        {
            ranges.append(r)
            searchStart = haystack.index(after: r.lowerBound)
        }
        return ranges
    }

    private static func filterOccurrences(
        _ ranges: [Range<String.Index>],
        in markdown: String,
        prefixText: String?,
        suffixText: String?
    ) -> [Range<String.Index>] {
        let p = prefixText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let s = suffixText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        guard p != nil || s != nil else { return ranges }

        return ranges.filter { r in
            let before = String(markdown[..<r.lowerBound])
            let after = String(markdown[r.upperBound...])

            if let p {
                let tail = String(before.suffix(min(60, before.count)))
                guard tail.contains(p) || before.hasSuffix(p) else { return false }
            }
            if let s {
                let head = String(after.prefix(min(60, after.count)))
                guard head.contains(s) || after.hasPrefix(s) else { return false }
            }
            return true
        }
    }

    private static func rangesOverlap(_ a: Range<String.Index>, _ b: Range<String.Index>) -> Bool {
        a.lowerBound < b.upperBound && b.lowerBound < a.upperBound
    }

    private static func colorToken(for color: YabaColor) -> String {
        switch color {
        case .none, .yellow: return "YELLOW"
        case .blue: return "BLUE"
        case .brown: return "BROWN"
        case .cyan: return "CYAN"
        case .gray: return "GRAY"
        case .green: return "GREEN"
        case .indigo: return "INDIGO"
        case .mint: return "MINT"
        case .orange: return "ORANGE"
        case .pink: return "PINK"
        case .purple: return "PURPLE"
        case .red: return "RED"
        case .teal: return "TEAL"
        }
    }
}

private extension Array where Element == Range<String.Index> {
    var singleOrNil: Range<String.Index>? {
        count == 1 ? first : nil
    }
}
