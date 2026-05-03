//
//  CanvasInlineApplyJsonDarwin.swift
//  YABACore
//
//  JSON strings for `window.YabaCanvasBridge.applyCanvasInline`, matching
//  `Extensions/yaba-web-components/src/bridge/canvas-inline.ts`.
//

import Foundation

public enum CanvasInlineApplyJsonDarwin {
    public static func insertTextWithUrl(displayText: String, url: String) -> String {
        let o: [String: Any] = [
            "op": "insertTextWithUrl",
            "displayText": displayText,
            "url": url,
        ]
        return jsonString(o) ?? "{}"
    }

    public static func insertTextWithMention(
        displayText: String,
        bookmarkId: String,
        bookmarkKindCode: Int,
        bookmarkLabel: String
    ) -> String {
        let o: [String: Any] = [
            "op": "insertTextWithMention",
            "displayText": displayText,
            "bookmarkId": bookmarkId,
            "bookmarkKindCode": bookmarkKindCode,
            "bookmarkLabel": bookmarkLabel,
        ]
        return jsonString(o) ?? "{}"
    }

    private static func jsonString(_ object: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []),
              let s = String(data: data, encoding: .utf8)
        else { return nil }
        return s
    }
}
