//
//  LinkmarkReadItLaterWebView.swift
//  YABAMobile
//

import Foundation
import SwiftUI
import WebKit

struct LinkmarkInlineAssetPayload: Sendable {
    let assetId: String
    let pathExtension: String
    let bytes: Data
}

private final class LinkmarkInlineAssetSchemeHandler: NSObject, WKURLSchemeHandler {
    private let lock = NSLock()
    private var assetsById: [String: LinkmarkInlineAssetPayload] = [:]

    func updateAssets(_ assets: [LinkmarkInlineAssetPayload]) {
        var map: [String: LinkmarkInlineAssetPayload] = [:]
        map.reserveCapacity(assets.count)
        for item in assets {
            map[item.assetId] = item
        }
        lock.lock()
        assetsById = map
        lock.unlock()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let requestURL = urlSchemeTask.request.url,
              let payload = resolveAsset(for: requestURL)
        else {
            let error = NSError(domain: "YABA.LinkmarkAssetScheme", code: 404)
            urlSchemeTask.didFailWithError(error)
            return
        }

        let response = URLResponse(
            url: requestURL,
            mimeType: mimeType(forPathExtension: payload.pathExtension),
            expectedContentLength: payload.bytes.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(payload.bytes)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func resolveAsset(for url: URL) -> LinkmarkInlineAssetPayload? {
        let candidateId = assetIdCandidate(for: url)
        guard let candidateId else { return nil }

        lock.lock()
        let payload = assetsById[candidateId]
        lock.unlock()
        return payload
    }

    private func assetIdCandidate(for url: URL) -> String? {
        let pathSegments = url.pathComponents.filter { $0 != "/" }
        if let last = pathSegments.last, !last.isEmpty {
            if last == "assets", let host = url.host, !host.isEmpty {
                return host
            }
            let base = (last as NSString).deletingPathExtension
            if !base.isEmpty {
                return base
            }
            return last
        }
        if let host = url.host, !host.isEmpty {
            let base = (host as NSString).deletingPathExtension
            return base.isEmpty ? host : base
        }
        return nil
    }

    private func mimeType(forPathExtension ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "svg": return "image/svg+xml"
        case "bmp": return "image/bmp"
        case "ico": return "image/x-icon"
        default: return "application/octet-stream"
        }
    }
}

struct LinkmarkReadItLaterWebView: UIViewRepresentable {
    let markdown: String
    let inlineAssets: [LinkmarkInlineAssetPayload]
    let readerPreferences: ReaderPreferences
    let appearance: WebAppearance
    let annotationsJson: String
    @Binding var tocNavigateItemId: String?
    @Binding var scrollToAnnotationId: String?
    let onHostEvent: (WebHostEvent) -> Void
    let onInlineLinkTap: (InlineLinkTapEvent) -> Void
    let onAnnotationTap: ((String) -> Void)?
    let onScrollShowChrome: (() -> Void)?
    let onScrollHideChrome: (() -> Void)?
    let onRuntimeReady: ((WKWebViewRuntime) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.runtime.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.updateBindings(toc: $tocNavigateItemId, scroll: $scrollToAnnotationId)
        context.coordinator.update(parent: self)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        private(set) var parent: LinkmarkReadItLaterWebView
        fileprivate let schemeHandler = LinkmarkInlineAssetSchemeHandler()
        let runtime: WKWebViewRuntime
        private var hasLoadedShell = false
        private var isBridgeReady = false
        private var lastScrollOffsetY: CGFloat?
        private var lastMarkdownApplied = ""
        private var lastPrefsFingerprint = ""
        private var tocNavigateBinding = Binding<String?>.constant(nil)
        private var scrollAnnotationBinding = Binding<String?>.constant(nil)

        init(parent: LinkmarkReadItLaterWebView) {
            self.parent = parent
            self.runtime = WKWebViewRuntime(
                configuration: WebRuntimeConfiguration(
                    websiteDataStore: .nonPersistent(),
                    yabaAssetSchemeHandler: schemeHandler
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
            runtime.onAnnotationTap = { [weak self] id in
                self?.parent.onAnnotationTap?(id)
            }
            runtime.webView.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                runtime.webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
        }

        func updateBindings(toc: Binding<String?>, scroll: Binding<String?>) {
            tocNavigateBinding = toc
            scrollAnnotationBinding = scroll
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
                    appearance: parent.appearance,
                    annotationsJson: parent.annotationsJson
                )
            )
        }

        @MainActor
        private func applyReaderBridgeStateAndNavigation() async {
            let markdown = parent.markdown
            let prefs = parent.readerPreferences
            let appearance = parent.appearance
            let annotationsJson = parent.annotationsJson

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
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.setAnnotations(jsonArrayBody: annotationsJson)
                )
                lastMarkdownApplied = markdown
                lastPrefsFingerprint = fp
            } else {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.setAnnotations(jsonArrayBody: annotationsJson)
                )
            }

            await flushNavigationCommands()
        }

        @MainActor
        private func flushNavigationCommands() async {
            if let tocId = tocNavigateBinding.wrappedValue, !tocId.isEmpty {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.navigateToTocItem(id: tocId, extrasJson: nil)
                )
                tocNavigateBinding.wrappedValue = nil
            }

            if let annId = scrollAnnotationBinding.wrappedValue, !annId.isEmpty {
                _ = try? await runtime.evaluateJavaScriptStringResult(
                    WebPreviewBridgeScripts.scrollToAnnotation(annotationId: annId)
                )
                scrollAnnotationBinding.wrappedValue = nil
            }
        }
    }
}
