//
//  YabaEditorDispatchPayload.swift
//  YABACore
//
//  JSON payloads for `window.YabaEditorBridge.dispatch` — mirrors Android `YabaEditorCommands`.
//

import Foundation

public enum YabaEditorDispatchPayload {
    public static let toggleBold = #"{"type":"toggleBold"}"#
    public static let toggleItalic = #"{"type":"toggleItalic"}"#
    /// Wraps selection with GFM-style `==highlight==`, or inserts `====` with caret between markers when empty.
    public static let toggleHighlight = #"{"type":"toggleHighlight"}"#
    public static let toggleStrikethrough = #"{"type":"toggleStrikethrough"}"#
    public static let toggleCode = #"{"type":"toggleCode"}"#
    public static let toggleCodeBlock = #"{"type":"toggleCodeBlock"}"#
    public static let toggleQuote = #"{"type":"toggleQuote"}"#
    public static let insertHr = #"{"type":"insertHr"}"#
    /// Inserts raw `<br>` plus newline at the caret (GFM / HTML-in-Markdown).
    public static let insertHtmlBr = #"{"type":"insertHtmlBr"}"#
    public static let toggleBulletedList = #"{"type":"toggleBulletedList"}"#
    public static let toggleNumberedList = #"{"type":"toggleNumberedList"}"#
    public static let toggleTaskList = #"{"type":"toggleTaskList"}"#
    public static let indent = #"{"type":"indent"}"#
    public static let outdent = #"{"type":"outdent"}"#
    public static let undo = #"{"type":"undo"}"#
    public static let redo = #"{"type":"redo"}"#

    public static func setHeading(level: Int) -> String {
        let l = min(max(level, 1), 6)
        return #"{"type":"setHeading","level":\#(l)}"#
    }

    /// When `asImage` is true, inserts `![text](url)` via the editor’s `insertLink` bridge with `image: true`
    /// (same dispatch path as normal links so bundled `editor.js` stays in sync).
    public static func insertLink(text: String, url: String, asImage: Bool = false) -> String {
        if asImage {
            struct InsertLinkAsImagePayload: Encodable {
                let type: String
                let text: String
                let url: String
                let image: Bool
            }
            do {
                return try WebJson.encodeToString(
                    InsertLinkAsImagePayload(type: "insertLink", text: text, url: url, image: true)
                )
            } catch {
                return #"{"type":"insertLink","text":"","url":"","image":true}"#
            }
        }
        struct InsertLinkPayload: Encodable {
            let type: String
            let text: String
            let url: String
        }
        do {
            return try WebJson.encodeToString(InsertLinkPayload(type: "insertLink", text: text, url: url))
        } catch {
            return #"{"type":"insertLink","text":"","url":""}"#
        }
    }

    /// Inserts a GFM pipe table at the selection — parity with Android `YabaEditorCommands.insertTablePayload`.
    public static func insertTable(rows: Int, cols: Int, withHeaderRow: Bool = false) -> String {
        struct InsertTablePayload: Encodable {
            let type: String
            let rows: Int
            let cols: Int
            let withHeaderRow: Bool
        }
        let r = min(max(rows, 1), 20)
        let c = min(max(cols, 1), 20)
        do {
            return try WebJson.encodeToString(
                InsertTablePayload(type: "insertTable", rows: r, cols: c, withHeaderRow: withHeaderRow)
            )
        } catch {
            return #"{"type":"insertTable","rows":3,"cols":3,"withHeaderRow":false}"#
        }
    }

    public static let insertInlineMathEmpty = #"{"type":"insertInlineMath","latex":""}"#
    public static let insertBlockMathEmpty = #"{"type":"insertBlockMath","latex":""}"#
}
