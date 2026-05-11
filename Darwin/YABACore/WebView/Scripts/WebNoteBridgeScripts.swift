//
//  WebNoteBridgeScripts.swift
//  YABACore
//
//  `evaluateJavaScript` bodies for `window.YabaNoteBridge` on unified `note.html` (notemark detail).
//

import CoreGraphics
import Foundation

public enum WebNoteBridgeScripts {
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
            var b = window.YabaNoteBridge;
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
            var b = window.YabaNoteBridge;
            if (!b || !b.setEditable) { return "no_bridge"; }
            b.setEditable(\(lit));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func disableViewportZoom() -> String {
        WebEditorBridgeScripts.disableViewportZoom()
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
            var b = window.YabaNoteBridge;
            if (!b) { return "no_bridge"; }
            if (b.setPlatform) { b.setPlatform('\(platformLit)'); }
            if (b.setAppearance) { b.setAppearance('\(appearanceLit)'); }
            if (b.setReaderPreferences) { b.setReaderPreferences(\(json)); }
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    /// Column sizing parity with `preview.html` / `WebPreviewBridgeScripts`.
    public static func applyReaderColumnLayout(_ layout: ReaderViewportColumnLayout) -> String {
        let w = min(100, max(1, layout.maxWidthVWPercent))
        let p = max(0, layout.horizontalPaddingPx)
        return """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || !b.setReaderColumnLayout) { return "no_bridge"; }
            b.setReaderColumnLayout({ maxWidthVWPercent: \(w), horizontalPaddingPx: \(p) });
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
            var b = window.YabaNoteBridge;
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

    public static func exportMarkdown() -> String {
        """
        (function(){
          try {
            var b = window.YabaNoteBridge;
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
            var b = window.YabaNoteBridge;
            if (!b || !b.getMarkdown) { return ""; }
            return b.getMarkdown() || "";
          } catch(e) { return ""; }
        })();
        """
    }

    public static func getUsedInlineAssetSrcs() -> String {
        """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || !b.getUsedInlineAssetSrcs) { return "[]"; }
            var s = b.getUsedInlineAssetSrcs();
            return (s && typeof s === "string") ? s : "[]";
          } catch(e) { return "[]"; }
        })();
        """
    }

    public static func getSyncedScrollFraction() -> String {
        """
        (function(){
          try {
            var b = window.YabaNoteBridge;
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
            var b = window.YabaNoteBridge;
            if (!b || !b.setSyncedScrollFraction) { return "no_bridge"; }
            b.setSyncedScrollFraction(\(t));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func unFocus() -> String {
        """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || typeof b.unFocus !== 'function') { return "no_bridge"; }
            b.unFocus();
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func dispatchCommand(_ payloadJson: String) -> String {
        let escaped = WebJsEscaping.escapeForJsSingleQuotedString(payloadJson)
        return """
        (function(){
          try {
            var payload = JSON.parse('\(escaped)');
            var b = window.YabaNoteBridge;
            if (!b || typeof b.dispatch !== 'function') { return "no_dispatch"; }
            b.dispatch(payload);
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func replaceHighlightColorMark(from: Int, to: Int, hexDigits: String) -> String {
        let hexLit = javaScriptStringLiteral(
            hexDigits.lowercased().replacingOccurrences(of: "#", with: "")
        )
        return """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || typeof b.replaceHighlightColorMark !== 'function') { return "no_bridge"; }
            b.replaceHighlightColorMark(\(from), \(to), \(hexLit));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func setSurfaceMode(_ mode: NotemarkDetailSurfaceMode) -> String {
        let literal: String
        switch mode {
        case .editor: literal = "editor"
        case .preview: literal = "preview"
        case .split: literal = "split"
        }
        return """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || typeof b.setSurfaceMode !== 'function') { return "no_bridge"; }
            b.setSurfaceMode('\(literal)');
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func togglePreviewTaskCheckbox(bracketOpen: Int) -> String {
        """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || typeof b.togglePreviewTaskCheckbox !== 'function') { return "no_bridge"; }
            b.togglePreviewTaskCheckbox(\(bracketOpen));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }

    public static func replacePreviewHighlightSyntax(
        syntaxStart: Int,
        syntaxEnd: Int,
        innerStart: Int,
        innerEnd: Int,
        hexDigits: String
    ) -> String {
        let hexLit = javaScriptStringLiteral(
            hexDigits.lowercased().replacingOccurrences(of: "#", with: "")
        )
        return """
        (function(){
          try {
            var b = window.YabaNoteBridge;
            if (!b || typeof b.replacePreviewHighlightSyntax !== 'function') { return "no_bridge"; }
            b.replacePreviewHighlightSyntax(\(syntaxStart), \(syntaxEnd), \(innerStart), \(innerEnd), \(hexLit));
            return "ok";
          } catch(e) { return String(e); }
        })();
        """
    }
}
