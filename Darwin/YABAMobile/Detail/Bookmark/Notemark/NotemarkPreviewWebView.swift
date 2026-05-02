//
//  NotemarkPreviewWebView.swift
//  YABA
//

import SwiftUI
import UIKit
import WebKit

/// Bundled Markdown preview (`preview.html`) host aligned with ``NotemarkEditorWebView``.
struct NotemarkPreviewWebView: UIViewRepresentable {
    let markdown: String
    let readerPreferences: ReaderPreferences
    let appearance: WebAppearance
    let markdownScrollHydrate: NotemarkWebScrollHydrate
    let onHostEvent: (WebHostEvent) -> Void
    var onRuntimeReady: ((WKWebViewRuntime) -> Void)?
    var onPreviewHighlightMarkTap: ((PreviewHighlightMarkTapEvent) -> Void)?
    var onPreviewTaskCheckboxTap: ((PreviewTaskCheckboxTapEvent) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.runtime.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.update(parent: self)
    }

    final class Coordinator: NSObject {
        private(set) var parent: NotemarkPreviewWebView
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        private var lastMarkdownApplied = ""
        private var lastPrefsFingerprint = ""
        private var lastHydrateTickApplied: UInt64 = 0

        init(parent: NotemarkPreviewWebView) {
            self.parent = parent
            self.runtime = WKWebViewRuntime(configuration: WebRuntimeConfiguration())
            super.init()
            runtime.onBridgeReady = { [weak self] in
                guard let self else { return }
                self.isBridgeReady = true
                self.parent.onRuntimeReady?(self.runtime)
                Task { @MainActor in
                    await self.applyPreviewBridgeState(isInitialBridgeReady: true)
                }
            }
            runtime.onHostEvent = { [weak self] event in
                self?.parent.onHostEvent(event)
            }
            runtime.webView.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                runtime.webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
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
        func update(parent: NotemarkPreviewWebView) {
            self.parent = parent
            if !hasLoadedShell {
                hasLoadedShell = true
                runtime.loadBundledShell(
                    for: .readItLater(
                        readerTheme: parent.readerPreferences.theme,
                        readerFontSize: parent.readerPreferences.fontSize,
                        readerLineHeight: parent.readerPreferences.lineHeight,
                        appearance: parent.appearance
                    )
                )
                return
            }
            guard isBridgeReady else { return }
            Task { await applyPreviewBridgeState(isInitialBridgeReady: false) }
        }

        @MainActor
        private func applyPreviewBridgeState(isInitialBridgeReady: Bool) async {
            let markdown = parent.markdown
            let prefs = parent.readerPreferences
            let appearance = parent.appearance

            let fp = "\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
            let markdownChanged = markdown != lastMarkdownApplied
            let prefsChanged = fp != lastPrefsFingerprint

            if markdownChanged || prefsChanged || isInitialBridgeReady {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.disableViewportZoom()
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.applyReaderHostPreferences(
                        appearance: appearance,
                        prefs: prefs
                    )
                )
                _ = try? await runtime.evaluateJavaScriptStringResult(WebPreviewBridgeScripts.setMarkdown(markdown))
                lastMarkdownApplied = markdown
                lastPrefsFingerprint = fp
            }

            await applyScrollHydrateIfNeeded()
        }

        @MainActor
        private func applyScrollHydrateIfNeeded() async {
            let hydrate = parent.markdownScrollHydrate
            guard hydrate.tick > 0, hydrate.tick != lastHydrateTickApplied else { return }
            lastHydrateTickApplied = hydrate.tick
            await applySyncedScrollFraction(hydrate.fraction)
        }

        @MainActor
        private func applySyncedScrollFraction(_ fraction: Double) async {
            for _ in 0 ..< 3 {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.setSyncedScrollFraction(fraction)
                )
                try? await Task.sleep(nanoseconds: 48_000_000)
            }
        }
    }
}
