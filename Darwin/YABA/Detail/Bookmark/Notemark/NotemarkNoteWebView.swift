//
//  NotemarkNoteWebView.swift
//  YABA
//

import SwiftUI
import UIKit
import WebKit

/// Pins `WKWebView` to all edges — `WKWebView` has no intrinsic size (same pattern as the prior editor-only host).
final class NotemarkNoteWebContainerView: UIView {
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

/// Unified `note.html` host: editor + preview in one `WKWebView`.
struct NotemarkNoteWebView: UIViewRepresentable {
    let markdown: String
    let inlineAssets: [YabaInlineAssetPayload]
    let readerPreferences: ReaderPreferences
    let appearance: WebAppearance
    /// Matches `NotemarkDetailUIState.surfaceMode` — drives `YabaNoteBridge.setSurfaceMode`.
    let surfaceMode: NotemarkDetailSurfaceMode
    let onHostEvent: (WebHostEvent) -> Void
    let onPersistDocument: (WKWebViewRuntime) async -> Void
    var onRuntimeReady: ((WKWebViewRuntime) -> Void)?
    var onHighlightColorMarkTap: ((HighlightColorMarkTapEvent) -> Void)?
    var onInlineLinkTap: ((InlineLinkTapEvent) -> Void)?
    var onPreviewHighlightMarkTap: ((PreviewHighlightMarkTapEvent) -> Void)?
    var onPreviewTaskCheckboxTap: ((PreviewTaskCheckboxTapEvent) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> NotemarkNoteWebContainerView {
        NotemarkNoteWebContainerView(webView: context.coordinator.runtime.webView)
    }

    func updateUIView(_ uiView: NotemarkNoteWebContainerView, context: Context) {
        context.coordinator.update(parent: self)
    }

    final class Coordinator: NSObject {
        private(set) var parent: NotemarkNoteWebView
        fileprivate let schemeHandler: YabaInlineAssetSchemeHandler
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        private var didHydrateInitialMarkdownFromHost = false
        private var lastPrefsFingerprint = ""
        private var lastSurfaceModeApplied: NotemarkDetailSurfaceMode?

        init(parent: NotemarkNoteWebView) {
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
                    await self.applyNoteBridgeState(forceSurfaceMode: true)
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
            runtime.onInlineLinkTap = { [weak self] ev in
                guard let self else { return }
                self.parent.onInlineLinkTap?(ev)
            }
            runtime.onPreviewHighlightMarkTap = { [weak self] ev in
                guard let self else { return }
                self.parent.onPreviewHighlightMarkTap?(ev)
            }
            runtime.onPreviewTaskCheckboxTap = { [weak self] ev in
                guard let self else { return }
                self.parent.onPreviewTaskCheckboxTap?(ev)
            }
        }

        @MainActor
        func update(parent: NotemarkNoteWebView) {
            self.parent = parent
            schemeHandler.updateAssets(parent.inlineAssets)
            if !hasLoadedShell {
                hasLoadedShell = true
                runtime.loadBundledShell(
                    for: .note(
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
            Task { await applyNoteBridgeState(forceSurfaceMode: false) }
        }

        @MainActor
        private func applyNoteBridgeState(forceSurfaceMode: Bool) async {
            let markdown = parent.markdown
            let prefs = parent.readerPreferences
            let appearance = parent.appearance
            let surface = parent.surfaceMode
            let fp = "\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
            let prefsChanged = fp != lastPrefsFingerprint
            let modeChanged = lastSurfaceModeApplied != surface || forceSurfaceMode

            if !didHydrateInitialMarkdownFromHost {
                didHydrateInitialMarkdownFromHost = true
                _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.disableViewportZoom())
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebNoteBridgeScripts.applyReaderHostPreferences(appearance: appearance, prefs: prefs)
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebNoteBridgeScripts.applyReaderColumnLayout(Self.readerColumnLayoutForCurrentDevice())
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.setEditable(true))
                _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.setMarkdown(markdown, assetsBaseUrl: nil))
                _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.setSurfaceMode(surface))
                lastPrefsFingerprint = fp
                lastSurfaceModeApplied = surface
                return
            }

            if modeChanged {
                _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.setSurfaceMode(surface))
                lastSurfaceModeApplied = surface
            }

            guard prefsChanged else { return }

            _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.disableViewportZoom())
            _ = try? await runtime.evaluateJavaScriptStringResult(
                WebNoteBridgeScripts.applyReaderHostPreferences(appearance: appearance, prefs: prefs)
            )
            _ = try? await runtime.evaluateJavaScriptStringResult(
                WebNoteBridgeScripts.applyReaderColumnLayout(Self.readerColumnLayoutForCurrentDevice())
            )
            _ = try? await runtime.evaluateJavaScriptStringResult(WebNoteBridgeScripts.setEditable(true))
            lastPrefsFingerprint = fp
        }

        private static func readerColumnLayoutForCurrentDevice() -> ReaderViewportColumnLayout {
            #if targetEnvironment(macCatalyst)
                return ReaderViewportColumnLayout(maxWidthVWPercent: 70, horizontalPaddingPx: 16)
            #else
                return ReaderViewportColumnLayout(maxWidthVWPercent: 100, horizontalPaddingPx: 0)
            #endif
        }
    }
}
