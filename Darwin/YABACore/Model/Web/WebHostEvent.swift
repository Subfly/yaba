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
}
