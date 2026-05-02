//
//  NotemarkDetailSurfaceMode.swift
//  YABACore
//

import Foundation

/// Editor vs Markdown preview chrome for notemark detail (`editor.html` / `preview.html`).
public enum NotemarkDetailSurfaceMode: String, Sendable, Equatable, CaseIterable {
    case editor
    case preview
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
