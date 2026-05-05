//
//  NativeHostMessageParserDarwin.swift
//  YABACore
//
//  Parity with Compose `YabaNativeHostMessageParser.kt` — must stay aligned with
//  `Extensions/yaba-web-components/src/bridge/contracts/native-host.ts`.
//

import Foundation

public enum NativeHostMessageParserDarwin {
    /// JSON numbers often decode as `NSNumber` / `Double`; direct `as? Int` can fail.
    private static func jsonInt(_ root: [String: Any], key: String) -> Int {
        let any = root[key]
        switch any {
        case let i as Int:
            return i
        case let n as NSNumber:
            return n.intValue
        case let s as String:
            return Int(s) ?? -1
        default:
            return -1
        }
    }

    public static func parse(
        json: String,
        onMathTap: ((MathTapEvent) -> Void)? = nil,
        onInlineLinkTap: ((InlineLinkTapEvent) -> Void)? = nil,
        onInlineMentionTap: ((InlineMentionTapEvent) -> Void)? = nil,
        onHighlightColorMarkTap: ((HighlightColorMarkTapEvent) -> Void)? = nil,
        onPreviewHighlightMarkTap: ((PreviewHighlightMarkTapEvent) -> Void)? = nil,
        onPreviewTaskCheckboxTap: ((PreviewTaskCheckboxTapEvent) -> Void)? = nil
    ) -> WebHostEvent? {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = root["type"] as? String
        else {
            return nil
        }

        switch type {
        case "shellLoad":
            return parseShellLoad(root)
        case "noteAutosaveIdle":
            return .noteEditorIdleForAutosave
        case "readerMetrics":
            return parseReaderMetrics(root)
        case "mathTap":
            let kind = root["kind"] as? String ?? ""
            let pos = root["pos"] as? Int ?? -1
            let latex = root["latex"] as? String ?? ""
            if pos >= 0 {
                onMathTap?(
                    MathTapEvent(
                        isBlock: kind == "block",
                        documentPos: pos,
                        latex: latex
                    )
                )
            }
            return nil
        case "inlineLinkTap":
            let pos = root["pos"] as? Int ?? -1
            let text = root["text"] as? String ?? ""
            let url = root["url"] as? String ?? ""
            if pos >= 0, !url.isEmpty {
                onInlineLinkTap?(
                    InlineLinkTapEvent(documentPos: pos, text: text, url: url)
                )
            }
            return nil
        case "inlineMentionTap":
            let pos = root["pos"] as? Int ?? -1
            let text = root["text"] as? String ?? ""
            let bookmarkId = root["bookmarkId"] as? String ?? ""
            let bookmarkKindCode = root["bookmarkKindCode"] as? Int ?? 0
            let bookmarkLabel = root["bookmarkLabel"] as? String ?? ""
            if pos >= 0, !bookmarkId.isEmpty {
                onInlineMentionTap?(
                    InlineMentionTapEvent(
                        documentPos: pos,
                        text: text,
                        bookmarkId: bookmarkId,
                        bookmarkKindCode: bookmarkKindCode,
                        bookmarkLabel: bookmarkLabel
                    )
                )
            }
            return nil
        case "noteHighlightColorMarkTap":
            let from = root["from"] as? Int ?? -1
            let to = root["to"] as? Int ?? -1
            let hex = (root["hex"] as? String ?? "").lowercased().replacingOccurrences(of: "#", with: "")
            if from >= 0, to >= from, hex.count == 6 {
                onHighlightColorMarkTap?(
                    HighlightColorMarkTapEvent(from: from, to: to, hexDigits: hex)
                )
            }
            return nil
        case "previewHighlightMarkTap":
            let syntaxStart = jsonInt(root, key: "syntaxStart")
            let syntaxEnd = jsonInt(root, key: "syntaxEnd")
            let innerStart = jsonInt(root, key: "innerStart")
            let innerEnd = jsonInt(root, key: "innerEnd")
            let hex = (root["hex"] as? String ?? "").lowercased().replacingOccurrences(of: "#", with: "")
            if syntaxStart >= 0, syntaxEnd > syntaxStart, innerStart >= 0, innerEnd >= innerStart, innerEnd <= syntaxEnd {
                onPreviewHighlightMarkTap?(
                    PreviewHighlightMarkTapEvent(
                        syntaxStart: syntaxStart,
                        syntaxEnd: syntaxEnd,
                        innerStart: innerStart,
                        innerEnd: innerEnd,
                        hexDigits: hex
                    )
                )
            }
            return nil
        case "previewTaskCheckboxTap":
            let bracketOpen = jsonInt(root, key: "bracketOpen")
            if bracketOpen >= 0 {
                onPreviewTaskCheckboxTap?(PreviewTaskCheckboxTapEvent(bracketOpen: bracketOpen))
            }
            return nil
        default:
            return nil
        }
    }

    private static func parseShellLoad(_ root: [String: Any]) -> WebHostEvent {
        let result = root["result"] as? String ?? ""
        let shell: WebShellLoadResult = (result == "loaded") ? .loaded : .error
        return .initialContentLoad(shell)
    }

    private static func parseReaderMetrics(_ root: [String: Any]) -> WebHostEvent {
        let page = max(1, root["currentPage"] as? Int ?? 1)
        let count = max(1, root["pageCount"] as? Int ?? 1)
        var formatting: EditorFormattingState?
        if let fmt = root["formatting"] as? [String: Any] {
            formatting = parseEditorFormatting(fmt)
        }
        return .readerMetrics(
            ReaderMetricsEvent(
                currentPage: page,
                pageCount: count,
                formatting: formatting
            )
        )
    }

    private static func parseEditorFormatting(_ json: [String: Any]) -> EditorFormattingState {
        EditorFormattingState(
            headingLevel: json["headingLevel"] as? Int ?? 0,
            bold: json["bold"] as? Bool ?? false,
            italic: json["italic"] as? Bool ?? false,
            underline: json["underline"] as? Bool ?? false,
            strikethrough: json["strikethrough"] as? Bool ?? false,
            subscriptEnabled: json["subscript"] as? Bool ?? false,
            superscript: json["superscript"] as? Bool ?? false,
            code: json["code"] as? Bool ?? false,
            codeBlock: json["codeBlock"] as? Bool ?? false,
            blockquote: json["blockquote"] as? Bool ?? false,
            bulletList: json["bulletList"] as? Bool ?? false,
            orderedList: json["orderedList"] as? Bool ?? false,
            taskList: json["taskList"] as? Bool ?? false,
            inlineMath: json["inlineMath"] as? Bool ?? false,
            blockMath: json["blockMath"] as? Bool ?? false,
            canUndo: json["canUndo"] as? Bool ?? false,
            canRedo: json["canRedo"] as? Bool ?? false,
            canIndent: json["canIndent"] as? Bool ?? false,
            canOutdent: json["canOutdent"] as? Bool ?? false,
            inTable: json["inTable"] as? Bool ?? false,
            canAddRowBefore: json["canAddRowBefore"] as? Bool ?? false,
            canAddRowAfter: json["canAddRowAfter"] as? Bool ?? false,
            canDeleteRow: json["canDeleteRow"] as? Bool ?? false,
            canAddColumnBefore: json["canAddColumnBefore"] as? Bool ?? false,
            canAddColumnAfter: json["canAddColumnAfter"] as? Bool ?? false,
            canDeleteColumn: json["canDeleteColumn"] as? Bool ?? false,
            textHighlight: json["textHighlight"] as? Bool ?? false
        )
    }
}
