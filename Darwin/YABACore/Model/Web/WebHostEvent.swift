//
//  WebHostEvent.swift
//  YABACore
//
//  Events from `window.YabaNativeHost.postMessage` (see `Extensions/yaba-web-components/.../native-host.ts`).
//

import Foundation

public enum WebHostEvent: Sendable {
    case loadState(WebLoadState)
    case initialContentLoad(WebShellLoadResult)
    case readerMetrics(ReaderMetricsEvent)
    case noteEditorIdleForAutosave
    case canvasIdleForAutosave
    case canvasMetrics(CanvasHostMetrics)
    case canvasStyleState(CanvasHostStyleState)
    case canvasLinkTap(elementId: String, text: String, url: String)
    case canvasMentionTap(
        elementId: String,
        text: String,
        bookmarkId: String,
        bookmarkKindCode: Int,
        bookmarkLabel: String
    )
}
