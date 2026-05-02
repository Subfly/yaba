//
//  WebRuntimeConfiguration.swift
//  YABACore
//

import WebKit

/// Tunable knobs for `WKWebViewRuntime`.
public struct WebRuntimeConfiguration: @unchecked Sendable {
    public var websiteDataStore: WKWebsiteDataStore

    /// When set, registers a `WKURLSchemeHandler` for the `yaba-asset` scheme (inline reader images from SwiftData).
    public var yabaAssetSchemeHandler: (WKURLSchemeHandler & NSObject)?

    /// When `true`, the runtime uses ``YabaInputAccessoryWKWebView`` so you can replace the keyboard accessory via ``YabaInputAccessoryWKWebView/accessoryView``.
    public var usesInputAccessoryHostingWebView: Bool

    public init(
        websiteDataStore: WKWebsiteDataStore = .nonPersistent(),
        yabaAssetSchemeHandler: (WKURLSchemeHandler & NSObject)? = nil,
        usesInputAccessoryHostingWebView: Bool = false
    ) {
        self.websiteDataStore = websiteDataStore
        self.yabaAssetSchemeHandler = yabaAssetSchemeHandler
        self.usesInputAccessoryHostingWebView = usesInputAccessoryHostingWebView
    }
}
