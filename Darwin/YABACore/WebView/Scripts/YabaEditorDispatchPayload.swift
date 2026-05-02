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
    public static let toggleStrikethrough = #"{"type":"toggleStrikethrough"}"#
    public static let toggleCode = #"{"type":"toggleCode"}"#
    public static let toggleCodeBlock = #"{"type":"toggleCodeBlock"}"#
    public static let toggleQuote = #"{"type":"toggleQuote"}"#
    public static let insertHr = #"{"type":"insertHr"}"#
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

    public static let insertInlineMathEmpty = #"{"type":"insertInlineMath","latex":""}"#
    public static let insertBlockMathEmpty = #"{"type":"insertBlockMath","latex":""}"#
}
