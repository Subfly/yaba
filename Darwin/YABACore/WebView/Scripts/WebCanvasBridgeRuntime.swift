//
//  WebCanvasBridgeRuntime.swift
//  YABACore
//
//  Convenience API on `WKWebViewRuntime` for the Excalidraw canvas shell.
//

import Foundation

extension WKWebViewRuntime {
    /// Persists host scene JSON from the embedded Excalidraw bridge.
    @MainActor
    public func canvasSnapshotSceneJson() async throws -> String {
        try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.getSceneJsonScript)
    }

    @MainActor
    public func canvasSetSceneJson(_ sceneJson: String) async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.setSceneJsonScript(sceneJson))
    }

    @MainActor
    public func canvasSetActiveTool(_ tool: String) async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.setActiveToolScript(tool))
    }

    @MainActor
    public func canvasUndo() async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.undoScript)
    }

    @MainActor
    public func canvasRedo() async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.redoScript)
    }

    @MainActor
    public func canvasDeleteSelected() async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.deleteSelectedScript)
    }

    @MainActor
    public func canvasInsertImage(dataUrl: String) async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.insertImageFromDataUrlScript(dataUrl))
    }

    @MainActor
    public func canvasApplyInline(payloadJson: String) async throws {
        _ = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.applyCanvasInlineScript(payloadJson))
    }

    /// PNG or SVG export; waits for async `exportImage` + poll slot (parity with Android).
    @MainActor
    public func canvasExportImageData(format: String, exportBackground: Bool) async -> Data? {
        let fmt = format.lowercased() == "svg" ? "svg" : "png"
        let bg = exportBackground ? "true" : "false"
        let requestJson = "{\"format\":\"\(fmt)\",\"exportBackground\":\(bg)}"
        do {
            _ = try await evaluateJavaScriptStringResult(
                WebCanvasBridgeScripts.exportCanvasImageKickoffScript(requestJson: requestJson)
            )
        } catch {
            return nil
        }

        for _ in 0 ..< 100 {
            do {
                let raw = try await evaluateJavaScriptStringResult(WebCanvasBridgeScripts.exportCanvasImagePollScript)
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    try await Task.sleep(nanoseconds: 48_000_000)
                    continue
                }
                return Self.decodeCanvasExportPayload(trimmed)
            } catch {
                return nil
            }
        }
        return nil
    }

    private static func decodeCanvasExportPayload(_ trimmed: String) -> Data? {
        guard let data = trimmed.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              root["ok"] as? Bool == true,
              let b64 = root["base64"] as? String,
              let out = Data(base64Encoded: b64, options: [.ignoreUnknownCharacters])
        else { return nil }
        return out
    }
}
