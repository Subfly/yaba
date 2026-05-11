//
//  WKWebViewRuntime.swift
//  YABACore
//
//  Shared `WKWebView` host: bridge injection, message routing, navigation policy, JS evaluation.
//

import Foundation
import WebKit

/// Owns a configured `WKWebView` for YABA web-component shells. Not tied to SwiftUI.
/// Callbacks are delivered on the main queue.
public final class WKWebViewRuntime: NSObject {
    public let webView: WKWebView

    public private(set) var expectedBridgeFeature: String?

    public var onHostEvent: ((WebHostEvent) -> Void)?
    public var onBridgeReady: (() -> Void)?
    public var onMathTap: ((MathTapEvent) -> Void)?
    public var onInlineLinkTap: ((InlineLinkTapEvent) -> Void)?
    public var onInlineMentionTap: ((InlineMentionTapEvent) -> Void)?
    public var onHighlightColorMarkTap: ((HighlightColorMarkTapEvent) -> Void)?
    public var onPreviewHighlightMarkTap: ((PreviewHighlightMarkTapEvent) -> Void)?
    public var onPreviewTaskCheckboxTap: ((PreviewTaskCheckboxTapEvent) -> Void)?

    public var onLoadProgress: ((Double) -> Void)?

    private let configuration: WebRuntimeConfiguration
    private let scriptBridge = ScriptBridgeProxy()
    private let navProxy = NavigationProxy()
    private let uiProxy = UIDelegateProxy()

    /// `WebViewClient.onPageFinished` and web `bridgeReady` must both be true before treating the shell as ready.
    private var pageLoadFinishedForCycle = false
    private var webPostedBridgeReadyForCycle = false
    private var emittedCombinedBridgeReadyForCycle = false

    public init(configuration: WebRuntimeConfiguration = WebRuntimeConfiguration()) {
        self.configuration = configuration
        let config = WKWebViewConfiguration()
        config.websiteDataStore = configuration.websiteDataStore
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        if let assetHandler = configuration.yabaAssetSchemeHandler {
            config.setURLSchemeHandler(assetHandler, forURLScheme: "yaba-asset")
        }
        config.userContentController.addUserScript(WKBridgeUserScript.nativeHostBridgeScript())
        config.userContentController.add(scriptBridge, name: NativeHostRouterDarwin.nativeHostScriptMessageName)
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let wv: WKWebView
        #if os(iOS) || targetEnvironment(macCatalyst)
        if configuration.usesInputAccessoryHostingWebView {
            wv = YabaInputAccessoryWKWebView(frame: .zero, configuration: config)
        } else {
            wv = WKWebView(frame: .zero, configuration: config)
        }
        #else
        wv = WKWebView(frame: .zero, configuration: config)
        #endif
        self.webView = wv

        super.init()

        scriptBridge.owner = self
        navProxy.owner = self
        uiProxy.owner = self

        webView.navigationDelegate = navProxy
        webView.uiDelegate = uiProxy
        #if os(iOS)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        #endif

        #if DEBUG
        if #available(iOS 16.4, macOS 13.3, macCatalyst 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.configuration.userContentController.removeScriptMessageHandler(forName: NativeHostRouterDarwin.nativeHostScriptMessageName)
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress), let w = object as? WKWebView {
            DispatchQueue.main.async { [weak self] in
                self?.onLoadProgress?(w.estimatedProgress)
            }
        }
    }

    /// Resolves the bundled shell URL and loads it with read access to the web-components directory.
    @MainActor
    public func loadBundledShell(for feature: WebFeature, bundle: Bundle = .main) {
        expectedBridgeFeature = feature.expectedBridgeFeature
        guard let url = Self.resolveShellURL(for: feature, bundle: bundle),
              let readAccess = BundleReader.webComponentsBaseURL(in: bundle) else {
            onHostEvent?(.loadState(.idle))
            return
        }
        resetBridgeReadinessCycle()
        onHostEvent?(.loadState(.loading(progressFraction: 0)))
        webView.loadFileURL(url, allowingReadAccessTo: readAccess)
    }

    /// Evaluates JavaScript and returns the JSON-string decoded result.
    @MainActor
    public func evaluateJavaScriptStringResult(_ script: String) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                if let s = result as? String {
                    cont.resume(returning: WebJsEscaping.decodeJavaScriptStringResult(s))
                } else if result == nil {
                    cont.resume(returning: "")
                } else {
                    cont.resume(returning: String(describing: result!))
                }
            }
        }
    }

    @MainActor
    fileprivate func handleScriptMessage(_ message: WKScriptMessage) {
        guard message.name == NativeHostRouterDarwin.nativeHostScriptMessageName else { return }
        let body: String
        if let s = message.body as? String {
            body = s
        } else if let dict = message.body as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict),
                  let str = String(data: data, encoding: .utf8) {
            body = str
        } else {
            return
        }
        dispatchNativeHostJSON(body)
    }

    @MainActor
    private func dispatchNativeHostJSON(_ json: String) {
        let handler = NativeHostRouterDarwin.createMessageHandler(
            expectedBridgeFeature: expectedBridgeFeature,
            onBridgeReady: { [weak self] in
                self?.markWebPostedBridgeReadyFromWeb()
            },
            onHostEvent: { [weak self] event in
                self?.onHostEvent?(event)
            },
            onMathTap: { [weak self] ev in
                self?.onMathTap?(ev)
            },
            onInlineLinkTap: { [weak self] ev in
                self?.onInlineLinkTap?(ev)
            },
            onInlineMentionTap: { [weak self] ev in
                self?.onInlineMentionTap?(ev)
            },
            onHighlightColorMarkTap: { [weak self] ev in
                self?.onHighlightColorMarkTap?(ev)
            },
            onPreviewHighlightMarkTap: { [weak self] ev in
                self?.onPreviewHighlightMarkTap?(ev)
            },
            onPreviewTaskCheckboxTap: { [weak self] ev in
                self?.onPreviewTaskCheckboxTap?(ev)
            }
        )
        handler(json)
    }

    @MainActor
    fileprivate func resetBridgeReadinessCycle() {
        pageLoadFinishedForCycle = false
        webPostedBridgeReadyForCycle = false
        emittedCombinedBridgeReadyForCycle = false
    }

    @MainActor
    fileprivate func markWebPostedBridgeReadyFromWeb() {
        webPostedBridgeReadyForCycle = true
        emitCombinedBridgeReadyIfNeeded()
    }

    @MainActor
    fileprivate func markPageLoadFinishedForBridgeReadiness() {
        pageLoadFinishedForCycle = true
        emitCombinedBridgeReadyIfNeeded()
        startBridgeReadinessProbingIfNeeded()
    }

    /// When `postMessage` does not reach the handler, poll the loaded bridge (editor or preview) like Android.
    fileprivate func startBridgeReadinessProbingIfNeeded() {
        guard !emittedCombinedBridgeReadyForCycle else { return }
        let probeJS = bridgeReadyProbeJavaScript()
        Task { @MainActor [weak self] in
            guard let self else { return }
            for _ in 0 ..< 50 {
                if self.emittedCombinedBridgeReadyForCycle { return }
                if await self.checkBridgeReadyViaJavaScript(probeJS) {
                    self.markWebPostedBridgeReadyFromWeb()
                    return
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func bridgeReadyProbeJavaScript() -> String {
        switch expectedBridgeFeature {
        case "preview":
            return WebBridgeScripts.previewBridgeReady
        case "note":
            return WebBridgeScripts.noteBridgeReady
        default:
            return WebBridgeScripts.editorBridgeReady
        }
    }

    @MainActor
    fileprivate func checkBridgeReadyViaJavaScript(_ script: String) async -> Bool {
        await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            self.webView.evaluateJavaScript(script) { result, _ in
                if let b = result as? Bool {
                    cont.resume(returning: b)
                } else if let n = result as? NSNumber {
                    cont.resume(returning: n.boolValue)
                } else {
                    cont.resume(returning: false)
                }
            }
        }
    }

    @MainActor
    fileprivate func emitCombinedBridgeReadyIfNeeded() {
        guard pageLoadFinishedForCycle, webPostedBridgeReadyForCycle, !emittedCombinedBridgeReadyForCycle else { return }
        emittedCombinedBridgeReadyForCycle = true
        onBridgeReady?()
        onHostEvent?(.loadState(.bridgeReady))
    }

    fileprivate func shouldAllow(navigationAction: WKNavigationAction) -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .cancel }
        let scheme = url.scheme?.lowercased() ?? ""

        switch scheme {
        case "about", "blob", "data", "javascript":
            return .allow
        case "file":
            return .allow
        case "yaba-asset":
            return .allow
        case "http", "https":
            return .allow
        default:
            return .cancel
        }
    }

    private static func resolveShellURL(for feature: WebFeature, bundle: Bundle) -> URL? {
        switch feature {
        case let .editor(_, _, _, appearance, _, _, _, _):
            return BundleReader.webShellURLWithQuery(
                named: "editor.html",
                platform: .darwin,
                appearance: appearance,
                bundle: bundle
            )
        case let .readItLater(_, _, _, appearance):
            return BundleReader.webShellURLWithQuery(
                named: "preview.html",
                platform: .darwin,
                appearance: appearance,
                bundle: bundle
            )
        case let .note(_, _, _, appearance, _, _, _, _):
            return BundleReader.webShellURLWithQuery(
                named: "note.html",
                platform: .darwin,
                appearance: appearance,
                bundle: bundle
            )
        }
    }
}

// MARK: - Navigation

private final class NavigationProxy: NSObject, WKNavigationDelegate {
    weak var owner: WKWebViewRuntime?

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.owner?.onHostEvent?(.loadState(.loading(progressFraction: nil)))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            guard let owner = self?.owner else { return }
            owner.onHostEvent?(.loadState(.pageFinished))
            owner.markPageLoadFinishedForBridgeReadiness()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.owner?.resetBridgeReadinessCycle()
            self?.owner?.onHostEvent?(.loadState(.idle))
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.owner?.resetBridgeReadinessCycle()
            self?.owner?.onHostEvent?(.loadState(.idle))
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let owner else {
            decisionHandler(.cancel)
            return
        }
        DispatchQueue.main.async {
            decisionHandler(owner.shouldAllow(navigationAction: navigationAction))
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        DispatchQueue.main.async { [weak self] in
            self?.owner?.resetBridgeReadinessCycle()
            self?.owner?.onHostEvent?(.loadState(.rendererCrashed))
        }
    }
}

// MARK: - UI delegate (deny new windows; deny media capture prompts at delegate level)

private final class UIDelegateProxy: NSObject, WKUIDelegate {
    weak var owner: WKWebViewRuntime?

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        nil
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.deny)
    }
}

// MARK: - Script message

private final class ScriptBridgeProxy: NSObject, WKScriptMessageHandler {
    weak var owner: WKWebViewRuntime?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        DispatchQueue.main.async { [weak self] in
            self?.owner?.handleScriptMessage(message)
        }
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)

extension WKWebViewRuntime {
    /// Present when created with `WebRuntimeConfiguration.usesInputAccessoryHostingWebView == true`.
    public var inputAccessoryHostingWebView: YabaInputAccessoryWKWebView? {
        webView as? YabaInputAccessoryWKWebView
    }
}

#endif
