//
//  LinkmarkReadItLaterWebView.swift
//  YABAMobile
//

import Foundation
import SwiftUI
import WebKit

struct LinkmarkReadItLaterWebView: UIViewRepresentable {
    let markdown: String
    let inlineAssets: [YabaInlineAssetPayload]
    let readerPreferences: ReaderPreferences
    let appearance: WebAppearance
    let onHostEvent: (WebHostEvent) -> Void
    let onInlineLinkTap: (InlineLinkTapEvent) -> Void
    let onScrollShowChrome: (() -> Void)?
    let onScrollHideChrome: (() -> Void)?
    let onRuntimeReady: ((WKWebViewRuntime) -> Void)?
    @Binding var readerPdfExport: LinkmarkReaderPdfExport?

    init(
        markdown: String,
        inlineAssets: [YabaInlineAssetPayload],
        readerPreferences: ReaderPreferences,
        appearance: WebAppearance,
        onHostEvent: @escaping (WebHostEvent) -> Void,
        onInlineLinkTap: @escaping (InlineLinkTapEvent) -> Void,
        onScrollShowChrome: (() -> Void)?,
        onScrollHideChrome: (() -> Void)?,
        readerPdfExport: Binding<LinkmarkReaderPdfExport?>,
        onRuntimeReady: ((WKWebViewRuntime) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.inlineAssets = inlineAssets
        self.readerPreferences = readerPreferences
        self.appearance = appearance
        self.onHostEvent = onHostEvent
        self.onInlineLinkTap = onInlineLinkTap
        self.onScrollShowChrome = onScrollShowChrome
        self.onScrollHideChrome = onScrollHideChrome
        self._readerPdfExport = readerPdfExport
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
        if let export = readerPdfExport {
            readerPdfExport = nil
            context.coordinator.exportPdfToDisk(parentDirectory: export.parentDirectory, fileBaseName: export.fileBaseName)
        }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        private(set) var parent: LinkmarkReadItLaterWebView
        fileprivate let schemeHandler: YabaInlineAssetSchemeHandler
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        private var lastScrollOffsetY: CGFloat?
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
            runtime.webView.scrollView.delegate = self
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
        }

        func exportPdfToDisk(parentDirectory: URL, fileBaseName: String) {
            let webView = runtime.webView
            let config = WKPDFConfiguration()
            let contentSize = webView.scrollView.contentSize
            var width = max(contentSize.width, webView.bounds.width)
            var height = max(contentSize.height, webView.bounds.height)
            if width < 1 { width = 612 }
            if height < 1 { height = 792 }
            config.rect = CGRect(x: 0, y: 0, width: width, height: height)
            webView.createPDF(configuration: config) { result in
                DispatchQueue.main.async {
                    switch result {
                    case let .success(data):
                        let ok = MarkdownExportSupport.writePdf(data: data, into: parentDirectory, fileBaseName: fileBaseName)
                        if !ok {
                            CoreToastManager.shared.show(
                                message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                                iconType: .error,
                                duration: .short
                            )
                        }
                    case .failure:
                        CoreToastManager.shared.show(
                            message: LocalizedStringKey("Bookmark Detail Markdown Export Failed Message"),
                            iconType: .error,
                            duration: .short
                        )
                    }
                }
            }
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let y = scrollView.contentOffset.y
            defer { lastScrollOffsetY = y }
            guard let last = lastScrollOffsetY else { return }
            let dy = y - last
            if dy > 8 {
                parent.onScrollHideChrome?()
            } else if dy < -8 {
                parent.onScrollShowChrome?()
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

            let fp = "\(prefs.theme.rawValue)|\(prefs.fontSize.rawValue)|\(prefs.lineHeight.rawValue)"
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
                    WebPreviewBridgeScripts.setMarkdown(markdown)
                )
                lastMarkdownApplied = markdown
                lastPrefsFingerprint = fp
            }
        }
    }
}
