//
//  CanvmarkEditorWebView.swift
//  YABA
//

import SwiftUI
import UIKit
import WebKit

/// Pins `WKWebView` for the bundled Excalidraw canvas shell (`canvas.html`).
final class CanvmarkCanvasContainerView: UIView {
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

/// Bundled `canvas.html` host for canvas bookmarks (`YabaCanvasBridge`).
struct CanvmarkEditorWebView: UIViewRepresentable {
    let bookmarkId: String
    let initialSceneJson: String
    let inlineAssets: [YabaInlineAssetPayload]
    let appearance: WebAppearance
    let folderCursorCss: String?
    let onHostEvent: (WebHostEvent) -> Void
    var onRuntimeReady: ((WKWebViewRuntime) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> CanvmarkCanvasContainerView {
        CanvmarkCanvasContainerView(webView: context.coordinator.runtime.webView)
    }

    func updateUIView(_ uiView: CanvmarkCanvasContainerView, context: Context) {
        context.coordinator.update(parent: self)
    }

    final class Coordinator: NSObject {
        private(set) var parent: CanvmarkEditorWebView
        fileprivate let schemeHandler: YabaInlineAssetSchemeHandler
        let runtime: WKWebViewRuntime
        private var isBridgeReady = false
        private var loadedBookmarkIdForShell: String?
        private var hydratedSceneBookmarkIds: Set<String> = []

        init(parent: CanvmarkEditorWebView) {
            self.parent = parent
            let handler = YabaInlineAssetSchemeHandler()
            handler.updateAssets(parent.inlineAssets)
            schemeHandler = handler
            runtime = WKWebViewRuntime(
                configuration: WebRuntimeConfiguration(
                    websiteDataStore: .nonPersistent(),
                    yabaAssetSchemeHandler: handler,
                    usesInputAccessoryHostingWebView: false
                )
            )
            super.init()
            runtime.onBridgeReady = { [weak self] in
                guard let self else { return }
                self.isBridgeReady = true
                self.parent.onRuntimeReady?(self.runtime)
                Task { @MainActor in
                    await self.hydrateStoredSceneOnceIfPossible()
                }
            }
            runtime.onHostEvent = { [weak self] event in
                self?.parent.onHostEvent(event)
            }
            runtime.webView.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                runtime.webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
        }

        @MainActor
        func update(parent: CanvmarkEditorWebView) {
            self.parent = parent
            schemeHandler.updateAssets(parent.inlineAssets)

            if loadedBookmarkIdForShell != parent.bookmarkId {
                hydratedSceneBookmarkIds.removeAll()
                loadedBookmarkIdForShell = parent.bookmarkId
                isBridgeReady = false
                runtime.loadBundledShell(
                    for: .canvas(
                        initialSceneJson: "",
                        appearance: parent.appearance,
                        sceneLoadGeneration: 0,
                        folderCursorCss: parent.folderCursorCss
                    )
                )
                return
            }

            guard isBridgeReady else { return }
            Task { await hydrateStoredSceneOnceIfPossible() }
        }

        @MainActor
        private func hydrateStoredSceneOnceIfPossible() async {
            guard isBridgeReady else { return }
            let bid = parent.bookmarkId
            guard loadedBookmarkIdForShell == bid else { return }
            guard !hydratedSceneBookmarkIds.contains(bid) else { return }
            do {
                try await runtime.canvasSetSceneJson(parent.initialSceneJson)
                hydratedSceneBookmarkIds.insert(bid)
            } catch {
                /* Next `update`/bridge-ready pass can retry until write succeeds */
            }
        }
    }
}
