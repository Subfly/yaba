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
