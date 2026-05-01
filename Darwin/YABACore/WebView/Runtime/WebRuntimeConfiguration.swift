//
//  WebRuntimeConfiguration.swift
//  YABACore
//

import WebKit

/// Tunable knobs for `WKWebViewRuntime` (security-first defaults).
public struct WebRuntimeConfiguration: @unchecked Sendable {
    public var websiteDataStore: WKWebsiteDataStore

    /// When set, registers a `WKURLSchemeHandler` for the `yaba-asset` scheme (inline reader images from SwiftData).
    public var yabaAssetSchemeHandler: (WKURLSchemeHandler & NSObject)?

    public init(
        websiteDataStore: WKWebsiteDataStore = .nonPersistent(),
        yabaAssetSchemeHandler: (WKURLSchemeHandler & NSObject)? = nil
    ) {
        self.websiteDataStore = websiteDataStore
        self.yabaAssetSchemeHandler = yabaAssetSchemeHandler
    }
}
