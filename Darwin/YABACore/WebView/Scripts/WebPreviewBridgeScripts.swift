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

    private static func javaScriptStringLiteral(_ s: String) -> String {
        guard let data = try? JSONEncoder().encode(s),
              let out = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }
        return out
    }

    /// Normalized scroll fraction `[0,1]` for `.yaba-preview-scroll` in `preview.html`.
    public static func getSyncedScrollFraction() -> String {
        """
        (function(){
          try {
            var b = window.YabaPreviewBridge;
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
            var b = window.YabaPreviewBridge;
            if (!b || !b.setSyncedScrollFraction) { return "no_bridge"; }
            b.setSyncedScrollFraction(\(t));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }
}
