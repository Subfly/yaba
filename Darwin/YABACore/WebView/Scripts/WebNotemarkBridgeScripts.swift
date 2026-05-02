//
//  WebNotemarkBridgeScripts.swift
//  YABACore
//

import Foundation

public enum WebNotemarkBridgeScripts {
    /// Fires `window` `CustomEvent` `yabaNativeNotemarkSurfaceMode` with `detail.mode` `"editor"` | `"preview"`.
    public static func dispatchSurfaceModeChange(_ mode: NotemarkDetailSurfaceMode) -> String {
        let literal = mode == .editor ? "editor" : "preview"
        return """
        (function(){
          try {
            var mode = '\(literal)';
            window.dispatchEvent(new CustomEvent('yabaNativeNotemarkSurfaceMode', { detail: { mode: mode } }));
            return 'ok';
          } catch (e) { return String(e); }
        })();
        """
    }
}
