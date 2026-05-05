//
//  WebBridgeScripts.swift
//  YABACore
//
//  One-line probes for `WKWebView.evaluateJavaScript` (editor + preview bridges).
//

import Foundation

public enum WebBridgeScripts {
    public static let editorBridgeReady = """
    (function(){ try { return !!(window.YabaEditorBridge && window.YabaEditorBridge.isReady && window.YabaEditorBridge.isReady()); } catch(e){ return false; } })();
    """

    public static let editorBridgeReadyLoose = """
    (function(){ try { return !!(window.YabaEditorBridge && window.YabaEditorBridge.isReady); } catch(e){ return false; } })();
    """

    public static let previewBridgeReady = """
    (function(){ try { return !!(window.YabaPreviewBridge && window.YabaPreviewBridge.isReady && window.YabaPreviewBridge.isReady()); } catch(e){ return false; } })();
    """

    public static let previewBridgeReadyLoose = """
    (function(){ try { return !!(window.YabaPreviewBridge && window.YabaPreviewBridge.isReady); } catch(e){ return false; } })();
    """
}
