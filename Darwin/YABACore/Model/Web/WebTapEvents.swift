//
//  WebTapEvents.swift
//  YABACore
//
//  Selection / link / mention payloads from the editor bridge (`native-host.ts`).
//

import Foundation

public struct MathTapEvent: Sendable {
    public var isBlock: Bool
    public var documentPos: Int
    public var latex: String

    public init(isBlock: Bool, documentPos: Int, latex: String) {
        self.isBlock = isBlock
        self.documentPos = documentPos
        self.latex = latex
    }
}

public struct InlineLinkTapEvent: Sendable {
    public var documentPos: Int
    public var text: String
    public var url: String

    public init(documentPos: Int, text: String, url: String) {
        self.documentPos = documentPos
        self.text = text
        self.url = url
    }
}

public struct InlineMentionTapEvent: Sendable {
    public var documentPos: Int
    public var text: String
    public var bookmarkId: String
    public var bookmarkKindCode: Int
    public var bookmarkLabel: String

    public init(
        documentPos: Int,
        text: String,
        bookmarkId: String,
        bookmarkKindCode: Int,
        bookmarkLabel: String
    ) {
        self.documentPos = documentPos
        self.text = text
        self.bookmarkId = bookmarkId
        self.bookmarkKindCode = bookmarkKindCode
        self.bookmarkLabel = bookmarkLabel
    }
}

/// `{#rrggbb}` secret editor color chip — web posts tap with UTF-16 offsets matching JS string indices for `evaluateJavaScript`.
public struct HighlightColorMarkTapEvent: Sendable {
    public var from: Int
    public var to: Int
    /// Six lowercase hex digits without `#`.
    public var hexDigits: String

    public init(from: Int, to: Int, hexDigits: String) {
        self.from = from
        self.to = to
        self.hexDigits = hexDigits
    }
}

/// Preview `<mark>` tap — UTF-16 offsets into stored Markdown for highlight syntax replacement.
public struct PreviewHighlightMarkTapEvent: Sendable {
    public var syntaxStart: Int
    public var syntaxEnd: Int
    public var innerStart: Int
    public var innerEnd: Int
    /// Empty when plain `==…==`; otherwise six lowercase hex digits without `#`.
    public var hexDigits: String

    public init(syntaxStart: Int, syntaxEnd: Int, innerStart: Int, innerEnd: Int, hexDigits: String) {
        self.syntaxStart = syntaxStart
        self.syntaxEnd = syntaxEnd
        self.innerStart = innerStart
        self.innerEnd = innerEnd
        self.hexDigits = hexDigits
    }
}

/// Preview task checkbox — UTF-16 index of `[` in `- [ ]` / `* [ ]` lines.
public struct PreviewTaskCheckboxTapEvent: Sendable {
    public var bracketOpen: Int

    public init(bracketOpen: Int) {
        self.bracketOpen = bracketOpen
    }
}
