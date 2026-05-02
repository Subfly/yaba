//
//  NativeHostRouterDarwin.swift
//  YABACore
//
//  Parity with Compose `YabaNativeHostRouter.kt` / `createNativeHostMessageHandler`.
//

import Foundation

public enum NativeHostRouterDarwin {
    public static let nativeHostScriptMessageName = "yabaNativeHost"

    /// Builds a JSON message handler callback for one WebView instance.
    public static func createMessageHandler(
        expectedBridgeFeature: String?,
        onBridgeReady: @escaping () -> Void,
        onHostEvent: @escaping (WebHostEvent) -> Void,
        onMathTap: @escaping (MathTapEvent) -> Void,
        onInlineLinkTap: @escaping (InlineLinkTapEvent) -> Void,
        onInlineMentionTap: @escaping (InlineMentionTapEvent) -> Void,
        onHighlightColorMarkTap: ((HighlightColorMarkTapEvent) -> Void)? = nil,
        onPreviewHighlightMarkTap: ((PreviewHighlightMarkTapEvent) -> Void)? = nil,
        onPreviewTaskCheckboxTap: ((PreviewTaskCheckboxTapEvent) -> Void)? = nil
    ) -> (String) -> Void {
        { json in
            guard let root = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
                  let type = root["type"] as? String
            else {
                return
            }

            switch type {
            case "bridgeReady":
                if let expectedBridgeFeature,
                   let feature = root["feature"] as? String,
                   feature == expectedBridgeFeature {
                    onBridgeReady()
                }
            default:
                if let event = NativeHostMessageParserDarwin.parse(
                    json: json,
                    onMathTap: onMathTap,
                    onInlineLinkTap: onInlineLinkTap,
                    onInlineMentionTap: onInlineMentionTap,
                    onHighlightColorMarkTap: onHighlightColorMarkTap,
                    onPreviewHighlightMarkTap: onPreviewHighlightMarkTap,
                    onPreviewTaskCheckboxTap: onPreviewTaskCheckboxTap
                ) {
                    onHostEvent(event)
                }
            }
        }
    }
}
