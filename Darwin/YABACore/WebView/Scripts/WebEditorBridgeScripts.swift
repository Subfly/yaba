//
//  WebEditorBridgeScripts.swift
//  YABACore
//
//  `evaluateJavaScript` bodies for `window.YabaEditorBridge` on CodeMirror `editor.html`.
//  Darwin link Markdown preview uses `preview.html` / `WebPreviewBridgeScripts` instead.
//

import CoreGraphics
import Foundation

public enum WebEditorBridgeScripts {
    /// CodeMirror / GFM markdown plus optional `assetsBaseUrl` for `../assets/` resolution.
    public static func setMarkdown(_ markdown: String, assetsBaseUrl: String?) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(markdown)
        let options: String
        if let assetsBaseUrl {
            let u = WebJsEscaping.escapeForJsSingleQuotedString(assetsBaseUrl)
            options = ", { assetsBaseUrl: '\(u)' }"
        } else {
            options = ""
        }
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setMarkdown) { return "no_bridge"; }
            b.setMarkdown('\(escaped)'\(options));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func setEditable(_ editable: Bool) -> String {
        let lit = editable ? "true" : "false"
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setEditable) { return "no_bridge"; }
            b.setEditable(\(lit));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func disableViewportZoom() -> String {
        """
        (function(){
          try {
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
              meta = document.createElement('meta');
              meta.setAttribute('name', 'viewport');
              var head = document.getElementsByTagName('head')[0];
              if (head) { head.appendChild(meta); }
            }
            meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func installEditorAnnotationTapHandler() -> String {
        """
        (function(){
          try {
            if (window.YabaEditorBridge) {
              window.YabaEditorBridge.onAnnotationTap = function(id) {
                var host = window.YabaNativeHost || window.YabaAndroidHost;
                if (id && host && host.postMessage) {
                  host.postMessage(JSON.stringify({type:'annotationTap',id:id}));
                }
              };
            }
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func setReaderPreferences(_ prefs: ReaderPreferences) -> String {
        let obj: [String: String] = [
            "theme": prefs.theme.rawValue,
            "fontSize": prefs.fontSize.rawValue,
            "lineHeight": prefs.lineHeight.rawValue,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []),
              let json = String(data: data, encoding: .utf8)
        else {
            return #"(() => "bad_json")()"#
        }
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setReaderPreferences) { return "no_bridge"; }
            b.setReaderPreferences(\(json));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func applyReaderHostPreferences(
        appearance: WebAppearance,
        prefs: ReaderPreferences
    ) -> String {
        let obj: [String: String] = [
            "theme": prefs.theme.rawValue,
            "fontSize": prefs.fontSize.rawValue,
            "lineHeight": prefs.lineHeight.rawValue,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: []),
              let json = String(data: data, encoding: .utf8)
        else {
            return #"(() => "bad_json")()"#
        }
        let platformLit = WebJsEscaping.escapeForJsSingleQuotedString(WebPlatform.darwin.rawValue)
        let appearanceLit = WebJsEscaping.escapeForJsSingleQuotedString(appearance.rawValue)
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b) { return "no_bridge"; }
            if (b.setPlatform) { b.setPlatform('\(platformLit)'); }
            if (b.setAppearance) { b.setAppearance('\(appearanceLit)'); }
            if (b.setReaderPreferences) { b.setReaderPreferences(\(json)); }
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    /// `AnnotationForRendering[]` JSON: `[{"id":"…","colorRole":"…"}]`.
    public static func setAnnotations(jsonArrayBody: String) -> String {
        let json = jsonArrayBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "[]" : jsonArrayBody
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(json)
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setAnnotations) { return "no_bridge"; }
            var parsed = JSON.parse('\(escaped)');
            b.setAnnotations(JSON.stringify(parsed));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func setWebChromeInsets(topPx: CGFloat) -> String {
        let t = Int(round(topPx))
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setWebChromeInsets) { return "no_bridge"; }
            b.setWebChromeInsets(\(t));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func navigateToTocItem(id: String, extrasJson: String?) -> String {
        let idJs = Self.javaScriptStringLiteral(id)
        let extrasJs: String
        if let extrasJson, !extrasJson.isEmpty {
            extrasJs = Self.javaScriptStringLiteral(extrasJson)
        } else {
            extrasJs = "null"
        }
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.navigateToTocItem) { return "no_bridge"; }
            b.navigateToTocItem(\(idJs), \(extrasJs));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    private static func javaScriptStringLiteral(_ s: String) -> String {
        guard let data = try? JSONEncoder().encode(s),
              let out = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return out
    }

    public static func setPlaceholder(_ text: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(text)
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setPlaceholder) { return "no_bridge"; }
            b.setPlaceholder('\(escaped)');
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func exportMarkdown() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.exportMarkdown) { return ""; }
            return b.exportMarkdown() || "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static func getMarkdown() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.getMarkdown) { return ""; }
            return b.getMarkdown() || "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static func scrollToAnnotation(annotationId: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(annotationId)
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.scrollToAnnotation) { return "no_bridge"; }
            b.scrollToAnnotation('\(escaped)');
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func getSelectionSnapshot() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.getSelectionSnapshot) { return ""; }
            var snapshot = b.getSelectionSnapshot();
            if (!snapshot) { return ""; }
            return JSON.stringify(snapshot);
          } catch(e) { return ""; }
        })();
        """
    }

    public static func getSelectedText() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.getSelectedText) { return ""; }
            var t = b.getSelectedText();
            return (t && typeof t === "string") ? t : "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static func getCanCreateAnnotation() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.getCanCreateAnnotation) { return "0"; }
            return b.getCanCreateAnnotation() ? "1" : "0";
          } catch(e) { return "0"; }
        })();
        """
    }

    public static func applyAnnotationToSelection(annotationId: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(annotationId)
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.applyAnnotationToSelection) { return "0"; }
            return b.applyAnnotationToSelection('\(escaped)') ? "1" : "0";
          } catch(e) { return "0"; }
        })();
        """
    }

    public static func removeAnnotationFromDocument(annotationId: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(annotationId)
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.removeAnnotationFromDocument) { return "0"; }
            var removed = b.removeAnnotationFromDocument('\(escaped)');
            if (typeof removed !== 'number' || !isFinite(removed)) { return "0"; }
            return String(Math.max(0, Math.floor(removed)));
          } catch(e) { return "0"; }
        })();
        """
    }
}
