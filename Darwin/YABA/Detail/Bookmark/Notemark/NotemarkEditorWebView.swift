//
//  NotemarkEditorWebView.swift
//  YABA
//

import SwiftUI
import WebKit

/// Pins `WKWebView` to all edges so SwiftUI layout proposals fill the screen (WKWebView has no intrinsic size).
final class NotemarkEditorContainerView: UIView {
    init(webView: WKWebView) {
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Bundled CodeMirror editor (`editor.html`) host for note bookmarks.
struct NotemarkEditorWebView: UIViewRepresentable {
    let markdown: String
    let inlineAssets: [YabaInlineAssetPayload]
    let readerPreferences: ReaderPreferences
    let appearance: WebAppearance
    let markdownScrollHydrate: NotemarkWebScrollHydrate
    let onHostEvent: (WebHostEvent) -> Void
    let onPersistDocument: (WKWebViewRuntime) async -> Void
    var onRuntimeReady: ((WKWebViewRuntime) -> Void)?
    var onHighlightColorMarkTap: ((HighlightColorMarkTapEvent) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> NotemarkEditorContainerView {
        NotemarkEditorContainerView(webView: context.coordinator.runtime.webView)
    }

    func updateUIView(_ uiView: NotemarkEditorContainerView, context: Context) {
        context.coordinator.update(parent: self)
    }

    final class Coordinator: NSObject {
        private(set) var parent: NotemarkEditorWebView
        fileprivate let schemeHandler: YabaInlineAssetSchemeHandler
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        /// After the first `setMarkdown` from SwiftUI, the web document is owned by the editor; pushing SwiftData-backed
        /// markdown again (e.g. after autosave) would reset the editor and dismiss the keyboard.
        private var didHydrateInitialMarkdownFromHost = false
        private var lastPrefsFingerprint = ""
        private var lastHydrateTickApplied: UInt64 = 0

        init(parent: NotemarkEditorWebView) {
            self.parent = parent
            let handler = YabaInlineAssetSchemeHandler()
            handler.updateAssets(parent.inlineAssets)
            self.schemeHandler = handler
            self.runtime = WKWebViewRuntime(
                configuration: WebRuntimeConfiguration(
                    websiteDataStore: .nonPersistent(),
                    yabaAssetSchemeHandler: handler,
                    usesInputAccessoryHostingWebView: true
                )
            )
            super.init()
            runtime.onBridgeReady = { [weak self] in
                guard let self else { return }
                self.isBridgeReady = true
                self.parent.onRuntimeReady?(self.runtime)
                Task { @MainActor in
                    await self.applyEditorBridgeState()
                }
            }
            runtime.onHostEvent = { [weak self] event in
                guard let self else { return }
                self.parent.onHostEvent(event)
                if case .noteEditorIdleForAutosave = event {
                    Task { @MainActor in
                        await self.parent.onPersistDocument(self.runtime)
                    }
                }
            }
            runtime.webView.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                runtime.webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
            runtime.onHighlightColorMarkTap = { [weak self] ev in
                guard let self else { return }
                self.parent.onHighlightColorMarkTap?(ev)
            }
        }

        @MainActor
        func update(parent: NotemarkEditorWebView) {
            self.parent = parent
            schemeHandler.updateAssets(parent.inlineAssets)
            if !hasLoadedShell {
                hasLoadedShell = true
                runtime.loadBundledShell(
                    for: .editor(
                        initialMarkdown: "",
                        assetsBaseUrl: nil,
                        placeholderText: nil,
                        appearance: parent.appearance,
                        readerTheme: parent.readerPreferences.theme,
                        readerFontSize: parent.readerPreferences.fontSize,
                        readerLineHeight: parent.readerPreferences.lineHeight,
                        documentLoadGeneration: 0
                    )
                )
                return
            }
            guard isBridgeReady else { return }
            Task { await applyEditorBridgeState() }
        }

        @MainActor
        private func applyEditorBridgeState() async {
            let markdown = parent.markdown
            let prefs = parent.readerPreferences
            let appearance = parent.appearance
            let fp = "\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
            let prefsChanged = fp != lastPrefsFingerprint

            if !didHydrateInitialMarkdownFromHost {
                // Set synchronously before awaits so concurrent MainActor tasks cannot double-hydrate.
                didHydrateInitialMarkdownFromHost = true
                _ = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.disableViewportZoom())
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebEditorBridgeScripts.applyReaderHostPreferences(appearance: appearance, prefs: prefs)
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.setEditable(true))
                _ = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.setMarkdown(markdown, assetsBaseUrl: nil))
                lastPrefsFingerprint = fp
                await applyScrollHydrateIfNeeded()
                return
            }

            guard prefsChanged else {
                await applyScrollHydrateIfNeeded()
                return
            }

            _ = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.disableViewportZoom())
            _ = try? await runtime.evaluateJavaScriptStringResult(
                WebEditorBridgeScripts.applyReaderHostPreferences(appearance: appearance, prefs: prefs)
            )
            _ = try? await runtime.evaluateJavaScriptStringResult(WebEditorBridgeScripts.setEditable(true))
            lastPrefsFingerprint = fp
            await applyScrollHydrateIfNeeded()
        }

        @MainActor
        private func applyScrollHydrateIfNeeded() async {
            let hydrate = parent.markdownScrollHydrate
            guard hydrate.tick > 0, hydrate.tick != lastHydrateTickApplied else { return }
            lastHydrateTickApplied = hydrate.tick
            for _ in 0 ..< 3 {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebEditorBridgeScripts.setSyncedScrollFraction(hydrate.fraction)
                )
                try? await Task.sleep(nanoseconds: 48_000_000)
            }
        }
    }
}
