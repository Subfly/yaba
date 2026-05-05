//
//  WebFeature.swift
//  YABACore
//
//  Bundled web shells for Darwin: CodeMirror editor (`editor.html`) and Markdown preview (`preview.html`).
//  Aligns with `YabaNativeHostFeature` in yaba-web-components.
//

import Foundation

/// Bundled web feature selection for `WKWebViewRuntime`.
public enum WebFeature: Sendable {
    /// CodeMirror Markdown editor (`editor.html`, `YabaEditorBridge`, `bridgeReady`: `editor`).
    case editor(
        initialMarkdown: String,
        assetsBaseUrl: String?,
        placeholderText: String?,
        appearance: WebAppearance,
        readerTheme: ReaderTheme,
        readerFontSize: ReaderFontSize,
        readerLineHeight: ReaderLineHeight,
        documentLoadGeneration: Int
    )

    /// Saved link Markdown preview (`preview.html`, `YabaPreviewBridge`, `bridgeReady`: `preview`).
    case readItLater(
        readerTheme: ReaderTheme,
        readerFontSize: ReaderFontSize,
        readerLineHeight: ReaderLineHeight,
        appearance: WebAppearance
    )

    /// `bridgeReady` `feature` string from the web layer (`native-host.ts`).
    public var expectedBridgeFeature: String {
        switch self {
        case .editor:
            return "editor"
        case .readItLater:
            return "preview"
        }
    }
}
