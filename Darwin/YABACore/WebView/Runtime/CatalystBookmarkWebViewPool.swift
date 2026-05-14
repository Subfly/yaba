//
//  CatalystBookmarkWebViewPool.swift
//  YABACore
//
//  Mac Catalyst: keep one warmed `WKWebView` per bookmark reader shell (`preview.html` + `note.html`)
//  so navigating linkmarks/notemarks avoids cold WebKit process startup latency.
//

import Foundation
import WebKit

#if targetEnvironment(macCatalyst)

/// Shared idle runtimes for bookmark-facing web surfaces (not Readium / other hosts).
@MainActor
public final class CatalystBookmarkWebViewPool {
    public static let shared = CatalystBookmarkWebViewPool()

    private struct PooledPair {
        let runtime: WKWebViewRuntime
        let schemeHandler: YabaInlineAssetSchemeHandler
        /// Last successfully loaded shell identity (used to skip `loadBundledShell` when preferences match prewarm).
        let shellFingerprint: String
    }

    private let prewarmAppearance: WebAppearance = .auto
    private let prewarmReaderPrefs = ReaderPreferences()

    private var idlePreview: PooledPair?
    private var idleNote: PooledPair?

    private init() {}

    /// Appearance + reader prefs that affect bundled `preview.html` query / shell URL.
    public static func readItLaterShellFingerprint(appearance: WebAppearance, prefs: ReaderPreferences) -> String {
        "ril|\(appearance.rawValue)|\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
    }

    /// Same for `note.html`.
    public static func noteShellFingerprint(appearance: WebAppearance, prefs: ReaderPreferences) -> String {
        "note|\(appearance.rawValue)|\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
    }

    /// Build idle `WKWebViewRuntime` instances and load shells so first detail navigation is mostly JS + content only.
    public func prewarmBookmarkShellsAtLaunchIfNeeded(bundle: Bundle = .main) {
        if idlePreview == nil {
            let handler = YabaInlineAssetSchemeHandler()
            let runtime = WKWebViewRuntime(
                configuration: WebRuntimeConfiguration(
                    websiteDataStore: .nonPersistent(),
                    yabaAssetSchemeHandler: handler,
                    usesInputAccessoryHostingWebView: false
                )
            )
            let fp = Self.readItLaterShellFingerprint(appearance: prewarmAppearance, prefs: prewarmReaderPrefs)
            runtime.loadBundledShell(
                for: .readItLater(
                    readerTheme: prewarmReaderPrefs.theme,
                    readerFontSize: prewarmReaderPrefs.fontSize,
                    readerLineHeight: prewarmReaderPrefs.lineHeight,
                    appearance: prewarmAppearance
                ),
                bundle: bundle
            )
            idlePreview = PooledPair(runtime: runtime, schemeHandler: handler, shellFingerprint: fp)
        }

        if idleNote == nil {
            let handler = YabaInlineAssetSchemeHandler()
            let runtime = WKWebViewRuntime(
                configuration: WebRuntimeConfiguration(
                    websiteDataStore: .nonPersistent(),
                    yabaAssetSchemeHandler: handler,
                    usesInputAccessoryHostingWebView: true
                )
            )
            let fp = Self.noteShellFingerprint(appearance: prewarmAppearance, prefs: prewarmReaderPrefs)
            runtime.loadBundledShell(
                for: .note(
                    initialMarkdown: "",
                    assetsBaseUrl: nil,
                    placeholderText: nil,
                    appearance: prewarmAppearance,
                    readerTheme: prewarmReaderPrefs.theme,
                    readerFontSize: prewarmReaderPrefs.fontSize,
                    readerLineHeight: prewarmReaderPrefs.lineHeight,
                    documentLoadGeneration: 0
                ),
                bundle: bundle
            )
            idleNote = PooledPair(runtime: runtime, schemeHandler: handler, shellFingerprint: fp)
        }
    }

    public struct CheckoutOutcome {
        public let runtime: WKWebViewRuntime
        public let schemeHandler: YabaInlineAssetSchemeHandler
        public let loanedFromPool: Bool
        public let pooledShellFingerprint: String?
    }

    public func checkoutReadItLaterRuntime() -> CheckoutOutcome {
        if let p = idlePreview {
            idlePreview = nil
            return CheckoutOutcome(
                runtime: p.runtime,
                schemeHandler: p.schemeHandler,
                loanedFromPool: true,
                pooledShellFingerprint: p.shellFingerprint
            )
        }
        let handler = YabaInlineAssetSchemeHandler()
        let runtime = WKWebViewRuntime(
            configuration: WebRuntimeConfiguration(
                websiteDataStore: .nonPersistent(),
                yabaAssetSchemeHandler: handler,
                usesInputAccessoryHostingWebView: false
            )
        )
        return CheckoutOutcome(
            runtime: runtime,
            schemeHandler: handler,
            loanedFromPool: false,
            pooledShellFingerprint: nil
        )
    }

    public func checkoutNoteRuntime() -> CheckoutOutcome {
        if let p = idleNote {
            idleNote = nil
            return CheckoutOutcome(
                runtime: p.runtime,
                schemeHandler: p.schemeHandler,
                loanedFromPool: true,
                pooledShellFingerprint: p.shellFingerprint
            )
        }
        let handler = YabaInlineAssetSchemeHandler()
        let runtime = WKWebViewRuntime(
            configuration: WebRuntimeConfiguration(
                websiteDataStore: .nonPersistent(),
                yabaAssetSchemeHandler: handler,
                usesInputAccessoryHostingWebView: true
            )
        )
        return CheckoutOutcome(
            runtime: runtime,
            schemeHandler: handler,
            loanedFromPool: false,
            pooledShellFingerprint: nil
        )
    }

    /// Return a pooled loan to the idle bucket. Ephemeral runtimes are not accepted here.
    public func checkinReadItLaterLoanIfPooled(
        loanedFromPool: Bool,
        runtime: WKWebViewRuntime,
        schemeHandler: YabaInlineAssetSchemeHandler,
        shellFingerprintWhenLoaded: String
    ) {
        guard loanedFromPool else { return }
        runtime.clearHostCallbacks()
        runtime.webView.stopLoading()
        runtime.webView.removeFromSuperview()
        schemeHandler.updateAssets([])
        idlePreview = PooledPair(runtime: runtime, schemeHandler: schemeHandler, shellFingerprint: shellFingerprintWhenLoaded)
    }

    public func checkinNoteLoanIfPooled(
        loanedFromPool: Bool,
        runtime: WKWebViewRuntime,
        schemeHandler: YabaInlineAssetSchemeHandler,
        shellFingerprintWhenLoaded: String
    ) {
        guard loanedFromPool else { return }
        runtime.clearHostCallbacks()
        runtime.webView.stopLoading()
        runtime.webView.removeFromSuperview()
        schemeHandler.updateAssets([])
        idleNote = PooledPair(runtime: runtime, schemeHandler: schemeHandler, shellFingerprint: shellFingerprintWhenLoaded)
    }
}

#endif
