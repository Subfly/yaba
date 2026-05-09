//
//  BookmarkShareMarkdownPreface.swift
//  YABA
//

import Foundation

enum BookmarkShareMarkdownPreface {
    /// `# {localized date/time}\n\n{body}`
    static func prefixedNoteMarkdown(body: String) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = .current

        let head = df.string(from: Date())
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBody.isEmpty {
            return "# \(head)"
        }
        return "# \(head)\n\n\(trimmedBody)"
    }
}
