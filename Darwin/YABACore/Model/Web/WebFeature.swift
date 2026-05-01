//
//  WebFeature.swift
//  YABACore
//
//  Bundled web shells for Darwin: CodeMirror editor (`editor.html`), same shell for read-it-later,
//  and Excalidraw canvas (`canvas.html`). Aligns with `YabaNativeHostFeature` in yaba-web-components.
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

    /// Read-it-later uses the same CodeMirror shell and bridge as `editor`; native supplies Markdown + reader prefs.
    case readItLater(
        initialMarkdown: String,
        assetsBaseUrl: String?,
        readerTheme: ReaderTheme,
        readerFontSize: ReaderFontSize,
        readerLineHeight: ReaderLineHeight,
        appearance: WebAppearance,
        annotationsJson: String
    )

    case canvas(
        initialSceneJson: String,
        appearance: WebAppearance,
        sceneLoadGeneration: Int
    )

    /// `bridgeReady` `feature` string from the web layer (`native-host.ts`).
    public var expectedBridgeFeature: String {
        switch self {
        case .editor, .readItLater:
            return "editor"
        case .canvas:
            return "canvas"
        }
    }
}
