//
//  LinkmarkReadItLaterWebView.swift
//  YABAMobile
//

import Foundation
import SwiftUI
import WebKit

#if MENU_ITEM
import AppKit

struct LinkmarkReadItLaterWebView: NSViewRepresentable {
    let markdown: String
    let inlineAssets: [YabaInlineAssetPayload]
    let readerPreferences: ReaderPreferences
    let readerColumnLayout: ReaderViewportColumnLayout
    let appearance: WebAppearance
    let onHostEvent: (WebHostEvent) -> Void
    let onInlineLinkTap: (InlineLinkTapEvent) -> Void
    let onRuntimeReady: ((WKWebViewRuntime) -> Void)?

    init(
        markdown: String,
        inlineAssets: [YabaInlineAssetPayload],
        readerPreferences: ReaderPreferences,
        readerColumnLayout: ReaderViewportColumnLayout = .fullWidth,
        appearance: WebAppearance,
        onHostEvent: @escaping (WebHostEvent) -> Void,
        onInlineLinkTap: @escaping (InlineLinkTapEvent) -> Void,
        onRuntimeReady: ((WKWebViewRuntime) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.inlineAssets = inlineAssets
        self.readerPreferences = readerPreferences
        self.readerColumnLayout = readerColumnLayout
        self.appearance = appearance
        self.onHostEvent = onHostEvent
        self.onInlineLinkTap = onInlineLinkTap
        self.onRuntimeReady = onRuntimeReady
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> WKWebView {
        context.coordinator.runtime.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.update(parent: self)
    }

    final class Coordinator: NSObject {
        private(set) var parent: LinkmarkReadItLaterWebView
        fileprivate let schemeHandler: YabaInlineAssetSchemeHandler
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        private var lastMarkdownApplied = ""
        private var lastPrefsFingerprint = ""

        init(parent: LinkmarkReadItLaterWebView) {
            self.parent = parent
            let handler = YabaInlineAssetSchemeHandler()
            handler.updateAssets(parent.inlineAssets)
            self.schemeHandler = handler
            self.runtime = WKWebViewRuntime(
                configuration: WebRuntimeConfiguration(
                    websiteDataStore: .nonPersistent(),
                    yabaAssetSchemeHandler: handler
                )
            )
            super.init()
            runtime.onBridgeReady = { [weak self] in
                guard let self else { return }
                self.isBridgeReady = true
                self.parent.onRuntimeReady?(self.runtime)
                Task { @MainActor in
                    await self.applyReaderBridgeStateAndNavigation()
                }
            }
            runtime.onHostEvent = { [weak self] event in
                self?.parent.onHostEvent(event)
            }
            runtime.onInlineLinkTap = { [weak self] event in
                self?.parent.onInlineLinkTap(event)
            }
        }

        @MainActor
        func update(parent: LinkmarkReadItLaterWebView) {
            self.parent = parent
            schemeHandler.updateAssets(parent.inlineAssets)
            if !hasLoadedShell {
                loadShell()
                return
            }
            guard isBridgeReady else { return }
            Task { await applyReaderBridgeStateAndNavigation() }
        }

        @MainActor
        private func loadShell() {
            hasLoadedShell = true
            runtime.loadBundledShell(
                for: .readItLater(
                    readerTheme: parent.readerPreferences.theme,
                    readerFontSize: parent.readerPreferences.fontSize,
                    readerLineHeight: parent.readerPreferences.lineHeight,
                    appearance: parent.appearance
                )
            )
        }

        @MainActor
        private func applyReaderBridgeStateAndNavigation() async {
            let markdown = parent.markdown
            let prefs = parent.readerPreferences
            let appearance = parent.appearance

            let fp =
                "\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
                + "|\(parent.readerColumnLayout.maxWidthVWPercent)|\(parent.readerColumnLayout.horizontalPaddingPx)"
            let markdownChanged = markdown != lastMarkdownApplied
            let prefsChanged = fp != lastPrefsFingerprint

            if markdownChanged || prefsChanged {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.disableViewportZoom()
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.applyReaderHostPreferences(
                        appearance: appearance,
                        prefs: prefs
                    )
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.applyReaderColumnLayout(parent.readerColumnLayout)
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.setMarkdown(markdown)
                )
                lastMarkdownApplied = markdown
                lastPrefsFingerprint = fp
            }
        }
    }
}

#else
import UIKit

struct LinkmarkReadItLaterWebView: UIViewRepresentable {
    let markdown: String
    let inlineAssets: [YabaInlineAssetPayload]
    let readerPreferences: ReaderPreferences
    let readerColumnLayout: ReaderViewportColumnLayout
    let appearance: WebAppearance
    let onHostEvent: (WebHostEvent) -> Void
    let onInlineLinkTap: (InlineLinkTapEvent) -> Void
    let onRuntimeReady: ((WKWebViewRuntime) -> Void)?

    init(
        markdown: String,
        inlineAssets: [YabaInlineAssetPayload],
        readerPreferences: ReaderPreferences,
        readerColumnLayout: ReaderViewportColumnLayout = .fullWidth,
        appearance: WebAppearance,
        onHostEvent: @escaping (WebHostEvent) -> Void,
        onInlineLinkTap: @escaping (InlineLinkTapEvent) -> Void,
        onRuntimeReady: ((WKWebViewRuntime) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.inlineAssets = inlineAssets
        self.readerPreferences = readerPreferences
        self.readerColumnLayout = readerColumnLayout
        self.appearance = appearance
        self.onHostEvent = onHostEvent
        self.onInlineLinkTap = onInlineLinkTap
        self.onRuntimeReady = onRuntimeReady
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.runtime.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.update(parent: self)
    }

    #if targetEnvironment(macCatalyst)
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.catalystTearDownForPool()
    }
    #endif

    final class Coordinator: NSObject {
        private(set) var parent: LinkmarkReadItLaterWebView
        fileprivate let schemeHandler: YabaInlineAssetSchemeHandler
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        private var lastMarkdownApplied = ""
        private var lastPrefsFingerprint = ""
        #if targetEnvironment(macCatalyst)
        /// When false, pooled runtime checkout was unavailable — dismiss without returning to idle bucket.
        private let catalystLoanedFromPool: Bool
        private let catalystReuseWarmShellFingerprint: String?
        private var catalystCommittedShellFingerprint = ""
        private var catalystDidTearDown = false
        #endif

        init(parent: LinkmarkReadItLaterWebView) {
            self.parent = parent

            #if targetEnvironment(macCatalyst)
                /// Pool + WKWebKit are main-thread-bound; coordinators are created synchronously while SwiftUI is on the main thread.
                let pooled = MainActor.assumeIsolated {
                    let checkout = CatalystBookmarkWebViewPool.shared.checkoutReadItLaterRuntime()
                    checkout.schemeHandler.updateAssets(parent.inlineAssets)
                    let parentFpWarm = CatalystBookmarkWebViewPool.readItLaterShellFingerprint(
                        appearance: parent.appearance,
                        prefs: parent.readerPreferences
                    )
                    let reuseWarmShell =
                        checkout.loanedFromPool
                        && checkout.pooledShellFingerprint == parentFpWarm
                        && checkout.runtime.isCombinedBridgeReady
                    return (
                        checkout.schemeHandler,
                        checkout.runtime,
                        checkout.loanedFromPool,
                        reuseWarmShell ? parentFpWarm : nil as String?
                    )
                }
                self.schemeHandler = pooled.0
                self.runtime = pooled.1
                self.catalystLoanedFromPool = pooled.2
                self.catalystReuseWarmShellFingerprint = pooled.3
            #else
                let handler = YabaInlineAssetSchemeHandler()
                handler.updateAssets(parent.inlineAssets)
                self.schemeHandler = handler
                self.runtime = WKWebViewRuntime(
                    configuration: WebRuntimeConfiguration(
                        websiteDataStore: .nonPersistent(),
                        yabaAssetSchemeHandler: handler
                    )
                )
            #endif

            super.init()

            runtime.onBridgeReady = { [weak self] in
                guard let self else { return }
                self.isBridgeReady = true
                self.parent.onRuntimeReady?(self.runtime)
                Task { @MainActor in
                    await self.applyReaderBridgeStateAndNavigation()
                }
            }
            runtime.onHostEvent = { [weak self] event in
                self?.parent.onHostEvent(event)
            }
            runtime.onInlineLinkTap = { [weak self] event in
                self?.parent.onInlineLinkTap(event)
            }
            runtime.webView.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                runtime.webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }

            #if targetEnvironment(macCatalyst)
                if let wf = catalystReuseWarmShellFingerprint {
                    hasLoadedShell = true
                    isBridgeReady = true
                    catalystCommittedShellFingerprint = wf
                    parent.onRuntimeReady?(runtime)
                    Task { @MainActor in
                        await applyReaderBridgeStateAndNavigation()
                    }
                }
            #endif
        }

        #if targetEnvironment(macCatalyst)
            fileprivate func catalystTearDownForPool() {
                MainActor.assumeIsolated {
                    guard !catalystDidTearDown else { return }
                    catalystDidTearDown = true
                    if catalystLoanedFromPool {
                        let fp =
                            catalystCommittedShellFingerprint.isEmpty
                                ? CatalystBookmarkWebViewPool.readItLaterShellFingerprint(
                                    appearance: parent.appearance,
                                    prefs: parent.readerPreferences
                                ) : catalystCommittedShellFingerprint
                        CatalystBookmarkWebViewPool.shared.checkinReadItLaterLoanIfPooled(
                            loanedFromPool: catalystLoanedFromPool,
                            runtime: runtime,
                            schemeHandler: schemeHandler,
                            shellFingerprintWhenLoaded: fp
                        )
                    } else {
                        runtime.clearHostCallbacks()
                        runtime.webView.stopLoading()
                        runtime.webView.removeFromSuperview()
                    }
                }
            }

            private static func catalystReadItLaterShellFingerprint(_ parent: LinkmarkReadItLaterWebView) -> String {
                MainActor.assumeIsolated {
                    CatalystBookmarkWebViewPool.readItLaterShellFingerprint(
                        appearance: parent.appearance,
                        prefs: parent.readerPreferences
                    )
                }
            }
        #endif

        @MainActor
        func update(parent: LinkmarkReadItLaterWebView) {
            self.parent = parent
            schemeHandler.updateAssets(parent.inlineAssets)
            if !hasLoadedShell {
                loadShell()
                return
            }
            guard isBridgeReady else { return }
            Task { await applyReaderBridgeStateAndNavigation() }
        }

        @MainActor
        private func loadShell() {
            hasLoadedShell = true
            #if targetEnvironment(macCatalyst)
                catalystCommittedShellFingerprint = Self.catalystReadItLaterShellFingerprint(parent)
            #endif
            runtime.loadBundledShell(
                for: .readItLater(
                    readerTheme: parent.readerPreferences.theme,
                    readerFontSize: parent.readerPreferences.fontSize,
                    readerLineHeight: parent.readerPreferences.lineHeight,
                    appearance: parent.appearance
                )
            )
        }

        @MainActor
        private func applyReaderBridgeStateAndNavigation() async {
            let markdown = parent.markdown
            let prefs = parent.readerPreferences
            let appearance = parent.appearance

            let fp =
                "\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
                + "|\(parent.readerColumnLayout.maxWidthVWPercent)|\(parent.readerColumnLayout.horizontalPaddingPx)"
            let markdownChanged = markdown != lastMarkdownApplied
            let prefsChanged = fp != lastPrefsFingerprint

            if markdownChanged || prefsChanged {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.disableViewportZoom()
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.applyReaderHostPreferences(
                        appearance: appearance,
                        prefs: prefs
                    )
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.applyReaderColumnLayout(parent.readerColumnLayout)
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.setMarkdown(markdown)
                )
                lastMarkdownApplied = markdown
                lastPrefsFingerprint = fp
            }
        }
    }
}

#endif
