//
//  WebPreviewBridgeScripts.swift
//  YABACore
//
//  `evaluateJavaScript` bodies for `window.YabaPreviewBridge` on `preview.html`.
//

import CoreGraphics
import Foundation

public enum WebPreviewBridgeScripts {
    public static func setMarkdown(_ markdown: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(markdown)
        return """
        (function(){
          try {
            var b = window.YabaPreviewBridge;
            if (!b || !b.setMarkdown) { return "no_bridge"; }
            b.setMarkdown('\(escaped)');
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
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
            if (!b || !b.navigateToTocItem) { return "no_bridge"; }
            b.navigateToTocItem(\(idJs), \(extrasJs));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func scrollToAnnotation(annotationId: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(annotationId)
        return """
        (function(){
          try {
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
            if (!b || !b.getCanCreateAnnotation) { return "0"; }
            return b.getCanCreateAnnotation() ? "1" : "0";
          } catch(e) { return "0"; }
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
}
