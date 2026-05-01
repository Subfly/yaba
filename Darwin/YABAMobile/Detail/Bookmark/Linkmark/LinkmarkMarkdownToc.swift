//
//  LinkmarkMarkdownToc.swift
//  YABAMobile
//
//  Builds a nested outline from link-readable Markdown ATX headings. IDs match the preview WebView:
//  first heading → `toc-h-0`, second → `toc-h-1`, … (same contract as `toc-from-markdown.ts`).
//

import Foundation

/// Heading outline row for the link reader Contents sheet.
struct LinkmarkMarkdownTocItem: Identifiable, Hashable {
    var id: String
    var title: String
    var level: Int
    var children: [LinkmarkMarkdownTocItem]

    init(id: String, title: String, level: Int, children: [LinkmarkMarkdownTocItem] = []) {
        self.id = id
        self.title = title
        self.level = level
        self.children = children
    }
}

private final class MutableTocNode {
    let id: String
    let title: String
    let level: Int
    var children: [MutableTocNode] = []

    init(id: String, title: String, level: Int) {
        self.id = id
        self.title = title
        self.level = level
    }

    func freeze() -> LinkmarkMarkdownTocItem {
        LinkmarkMarkdownTocItem(id: id, title: title, level: level, children: children.map { $0.freeze() })
    }
}

enum LinkmarkMarkdownTocBuilder {
    /// Top-level items only (each may contain nested children).
    static func build(from markdown: String) -> [LinkmarkMarkdownTocItem] {
        let headings = listMarkdownHeadings(markdown)
        guard !headings.isEmpty else { return [] }

        var roots: [MutableTocNode] = []
        var stack: [MutableTocNode] = []

        for h in headings {
            let node = MutableTocNode(id: "toc-h-\(h.index)", title: h.title, level: h.level)
            while let last = stack.last, last.level >= h.level {
                stack.removeLast()
            }
            if let parent = stack.last {
                parent.children.append(node)
            } else {
                roots.append(node)
            }
            stack.append(node)
        }

        return roots.map { $0.freeze() }
    }

    private struct HeadingRow {
        let index: Int
        let level: Int
        let title: String
    }

    private static func listMarkdownHeadings(_ md: String) -> [HeadingRow] {
        var headings: [HeadingRow] = []
        var lineStart = md.startIndex
        var index = 0

        while lineStart < md.endIndex {
            let lineEnd = md[lineStart...].firstIndex(of: "\n") ?? md.endIndex
            let line = String(md[lineStart..<lineEnd])

            // ATX heading: optional indent, 1–6 `#`, space, title (mirrors `toc-from-markdown.ts`).
            if let re = try? NSRegularExpression(pattern: #"^(\s*)(#{1,6})\s+(.+?)\s*$"#),
               let m = re.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let titleRange = Range(m.range(at: 3), in: line)
            {
                let hashesRange = Range(m.range(at: 2), in: line)!
                let level = line[hashesRange].count
                let title = String(line[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    headings.append(HeadingRow(index: index, level: level, title: title))
                    index += 1
                }
            }

            lineStart = lineEnd == md.endIndex ? md.endIndex : md.index(after: lineEnd)
        }

        return headings
    }
}

extension LinkmarkMarkdownTocItem {
    /// `OutlineGroup` Optional children hook (nil when leaf).
    var outlineChildren: [LinkmarkMarkdownTocItem]? {
        children.isEmpty ? nil : children
    }
}
