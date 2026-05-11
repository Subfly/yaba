//
//  NotemarkDetailSurfaceMode.swift
//  YABACore
//

import Foundation

/// Editor-only, preview-only, or split editor + preview chrome for notemark detail (`editor.html` / `preview.html`).
public enum NotemarkDetailSurfaceMode: String, Sendable, Equatable, CaseIterable {
    case editor
    case preview
    case split
}

extension NotemarkDetailSurfaceMode {
    /// Value sent to the editor `WKWebView` for ``WebNotemarkBridgeScripts/dispatchSurfaceModeChange(_:)`` (always `.editor` or `.preview`).
    public func bridgeModeForEditorRuntime() -> NotemarkDetailSurfaceMode {
        switch self {
        case .split, .editor:
            return .editor
        case .preview:
            return .preview
        }
    }

    /// Value sent to the preview `WKWebView` for ``WebNotemarkBridgeScripts/dispatchSurfaceModeChange(_:)`` (always `.editor` or `.preview`).
    public func bridgeModeForPreviewRuntime() -> NotemarkDetailSurfaceMode {
        switch self {
        case .split, .preview:
            return .preview
        case .editor:
            return .editor
        }
    }
}

/// Signals the embed to apply a fractional scroll sync after swapping surfaces (`getSyncedScrollFraction` / `setSyncedScrollFraction` in web bridges).
public struct NotemarkWebScrollHydrate: Sendable, Equatable {
    public var tick: UInt64
    public var fraction: Double

    public static let inactive = NotemarkWebScrollHydrate(tick: 0, fraction: 0)

    public init(tick: UInt64 = 0, fraction: Double = 0) {
        self.tick = tick
        self.fraction = fraction
    }

    public mutating func enqueueFraction(_ fraction: Double) {
        tick &+= 1
        self.fraction = fraction
    }
}
