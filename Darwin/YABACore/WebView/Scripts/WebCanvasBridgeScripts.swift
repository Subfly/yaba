//
//  WebCanvasBridgeScripts.swift
//  YABACore
//
//  `evaluateJavaScript` bodies for `window.YabaCanvasBridge` on `canvas.html`.
//  Parity with Compose `YabaCanvasBridgeScripts.kt`.
//

import Foundation

public enum WebCanvasBridgeScripts {
    public static func setSceneJsonScript(_ sceneJson: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(sceneJson)
        return """
        (function(){
          try {
            window.YabaCanvasBridge?.setSceneJson?.('\(escaped)');
            return "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static let getSceneJsonScript: String = """
    (function(){
      try {
        var b = window.YabaCanvasBridge;
        if (!b || !b.getSceneJson) { return ""; }
        var s = b.getSceneJson();
        return (typeof s === "string") ? s : "";
      } catch(e) { return ""; }
    })();
    """

    public static func setActiveToolScript(_ tool: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(tool)
        return """
        (function(){
          try {
            window.YabaCanvasBridge?.setActiveTool?.('\(escaped)');
            return "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static let undoScript: String = """
    (function(){
      try { window.YabaCanvasBridge?.undo?.(); return ""; } catch(e) { return ""; }
    })();
    """

    public static let redoScript: String = """
    (function(){
      try { window.YabaCanvasBridge?.redo?.(); return ""; } catch(e) { return ""; }
    })();
    """

    public static let deleteSelectedScript: String = """
    (function(){
      try { window.YabaCanvasBridge?.deleteSelected?.(); return ""; } catch(e) { return ""; }
    })();
    """

    public static func insertImageFromDataUrlScript(_ dataUrl: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(dataUrl)
        return """
        (function(){
          try {
            window.YabaCanvasBridge?.insertImageFromDataUrl?.('\(escaped)');
            return "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static func applyCanvasInlineScript(_ json: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(json)
        return """
        (function(){
          try {
            window.YabaCanvasBridge?.applyCanvasInline?.('\(escaped)');
            return "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static let getCanvasSelectionLinkContextScript: String = """
    (function(){
      try {
        var b = window.YabaCanvasBridge;
        if (!b || !b.getCanvasSelectionLinkContext) { return "{}"; }
        var s = b.getCanvasSelectionLinkContext();
        return (typeof s === "string") ? s : "{}";
      } catch(e) { return "{}"; }
    })();
    """

    public static func exportCanvasImageKickoffScript(requestJson: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(requestJson)
        return """
        (function(){
          try {
            delete window.__yabaCanvasExport;
            window.__yabaCanvasExport = { status: 'pending', value: null };
            var b = window.YabaCanvasBridge;
            if (!b || !b.exportImage) {
              window.__yabaCanvasExport = { status: 'ready', value: JSON.stringify({ok:false,error:'no_export'}) };
              return "";
            }
            var p = b.exportImage('\(escaped)');
            if (p && typeof p.then === 'function') {
              p.then(function(v) {
                window.__yabaCanvasExport = { status: 'ready', value: v };
              }).catch(function(e) {
                window.__yabaCanvasExport = { status: 'ready', value: JSON.stringify({ok:false,error:String(e)}) };
              });
            } else {
              window.__yabaCanvasExport = { status: 'ready', value: JSON.stringify({ok:false,error:'not_a_promise'}) };
            }
          } catch (e) {
            window.__yabaCanvasExport = { status: 'ready', value: JSON.stringify({ok:false,error:String(e)}) };
          }
          return "";
        })();
        """
    }

    public static let exportCanvasImagePollScript: String = """
    (function(){
      try {
        var w = window.__yabaCanvasExport;
        if (!w) return '';
        if (w.status === 'pending') return '';
        if (w.status === 'ready') {
          var v = w.value;
          delete window.__yabaCanvasExport;
          return (typeof v === 'string') ? v : '';
        }
      } catch (e) {}
      return '';
    })();
    """
}
