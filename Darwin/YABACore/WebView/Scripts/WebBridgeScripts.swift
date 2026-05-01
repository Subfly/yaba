//
//  WebBridgeScripts.swift
//  YABACore
//
//  One-line probes for `WKWebView.evaluateJavaScript` (editor + canvas bridges).
//

import Foundation

public enum WebBridgeScripts {
    public static let editorBridgeReady = """
    (function(){ try { return !!(window.YabaEditorBridge && window.YabaEditorBridge.isReady && window.YabaEditorBridge.isReady()); } catch(e){ return false; } })();
    """

    public static let editorBridgeReadyLoose = """
    (function(){ try { return !!(window.YabaEditorBridge && window.YabaEditorBridge.isReady); } catch(e){ return false; } })();
    """

    public static let canvasBridgeReady = """
    (function(){ try { return !!(window.YabaCanvasBridge && window.YabaCanvasBridge.isReady && window.YabaCanvasBridge.isReady()); } catch(e){ return false; } })();
    """

    public static let canvasBridgeReadyLoose = """
    (function(){ try { return !!(window.YabaCanvasBridge && window.YabaCanvasBridge.isReady); } catch(e){ return false; } })();
    """
}
