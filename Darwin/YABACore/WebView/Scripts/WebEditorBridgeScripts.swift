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

    /// JSON array string of canonical `../assets/<id>.<ext>` paths referenced by the document.
    public static func getUsedInlineAssetSrcs() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.getUsedInlineAssetSrcs) { return "[]"; }
            var s = b.getUsedInlineAssetSrcs();
            return (s && typeof s === "string") ? s : "[]";
          } catch(e) { return "[]"; }
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

    /// Normalized scroll fraction `[0,1]` for the Markdown editor surface (Codemirror `scrollDOM`).
    public static func getSyncedScrollFraction() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.getSyncedScrollFraction) { return "0"; }
            var s = b.getSyncedScrollFraction();
            return (s && typeof s === "string") ? s : "0";
          } catch(e) { return "0"; }
        })();
        """
    }

    public static func setSyncedScrollFraction(_ fraction: Double) -> String {
        let t = fraction.isFinite ? fraction : 0.0
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || !b.setSyncedScrollFraction) { return "no_bridge"; }
            b.setSyncedScrollFraction(\(t));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    /// Releases editor focus / IME — parity with Android `unFocusScript`.
    public static func unFocus() -> String {
        """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || typeof b.unFocus !== 'function') { return "no_bridge"; }
            b.unFocus();
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    /// Dispatches a rich-text command — JSON text embedded in a single-quoted `JSON.parse` (parity with Android `dispatchScript`).
    public static func dispatchCommand(_ payloadJson: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(payloadJson)
        return """
        (function(){
          try {
            var payload = JSON.parse('\(escaped)');
            var b = window.YabaEditorBridge;
            if (!b || typeof b.dispatch !== 'function') { return "no_dispatch"; }
            b.dispatch(payload);
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    /// Updates `{#hex}` secret color token after native `YabaColorPicker` — `hexDigits` is six chars, no `#`.
    public static func replaceHighlightColorMark(from: Int, to: Int, hexDigits: String) -> String {
        let hexLit = javaScriptStringLiteral(
            hexDigits.lowercased().replacingOccurrences(of: "#", with: "")
        )
        return """
        (function(){
          try {
            var b = window.YabaEditorBridge;
            if (!b || typeof b.replaceHighlightColorMark !== 'function') { return "no_bridge"; }
            b.replaceHighlightColorMark(\(from), \(to), \(hexLit));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

}
