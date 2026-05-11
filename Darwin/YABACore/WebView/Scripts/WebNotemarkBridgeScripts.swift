//
//  WebNotemarkBridgeScripts.swift
//  YABACore
//

import Foundation

public enum WebNotemarkBridgeScripts {
    /// Fires `window` `CustomEvent` `yabaNativeNotemarkSurfaceMode` with `detail.mode` `"editor"` | `"preview"`.
    public static func dispatchSurfaceModeChange(_ mode: NotemarkDetailSurfaceMode) -> String {
        let literal: String
        switch mode {
        case .editor:
            literal = "editor"
        case .preview:
            literal = "preview"
        case .split:
            preconditionFailure("Map .split with bridgeModeForEditorRuntime() / bridgeModeForPreviewRuntime() before dispatching.")
        }
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
