//
//  YabaColor.swift
//  YABACore
//
//  Parity with Compose `YabaColor.code` values.
//

import Foundation
import SwiftUI

public enum YabaColor: Int, Sendable, CaseIterable {
    case none = 0
    case blue = 1
    case brown = 2
    case cyan = 3
    case gray = 4
    case green = 5
    case indigo = 6
    case mint = 7
    case orange = 8
    case pink = 9
    case purple = 10
    case red = 11
    case teal = 12
    case yellow = 13
}

public extension YabaColor {
    func getUIColor() -> Color {
        switch self {
        case .blue: return .blue
        case .brown: return .brown
        case .cyan: return .cyan
        case .gray: return .gray
        case .green: return .green
        case .indigo: return .indigo
        case .mint: return .mint
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .yellow: return .yellow
        case .none: return .accentColor
        }
    }

    func getUIText() -> String {
        switch self {
        case .blue: return "Blue"
        case .brown: return "Brown"
        case .cyan: return "Cyan"
        case .gray: return "Gray"
        case .green: return "Green"
        case .indigo: return "Indigo"
        case .mint: return "Mint"
        case .orange: return "Orange"
        case .pink: return "Pink"
        case .purple: return "Purple"
        case .red: return "Red"
        case .teal: return "Teal"
        case .yellow: return "Yellow"
        case .none: return "Theme Color"
        }
    }

    /// Canonical 6-digit RGB (no `#`) — parity with web `yaba-accent-palette.ts`.
    public var canonicalHexDigits: String? {
        switch self {
        case .none: return nil
        case .blue: return "0088ff"
        case .brown: return "ac7f5e"
        case .cyan: return "00c0e8"
        case .gray: return "8e8e93"
        case .green: return "34c759"
        case .indigo: return "6155f5"
        case .mint: return "00c8b3"
        case .orange: return "ff8d28"
        case .pink: return "ff2d55"
        case .purple: return "cb30e0"
        case .red: return "ff383c"
        case .teal: return "00c3d0"
        case .yellow: return "ffcc00"
        }
    }

    /// Maps `{#hex}` digits to a picker case when they match the YABA palette.
    public static func fromPaletteHexDigits(_ raw: String) -> YabaColor? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: "#", with: "")
        guard s.count == 6 else { return nil }
        switch s {
        case "0088ff": return .blue
        case "ac7f5e": return .brown
        case "00c0e8": return .cyan
        case "8e8e93": return .gray
        case "34c759": return .green
        case "6155f5": return .indigo
        case "00c8b3": return .mint
        case "ff8d28": return .orange
        case "ff2d55": return .pink
        case "cb30e0": return .purple
        case "ff383c": return .red
        case "00c3d0": return .teal
        case "ffcc00": return .yellow
        default: return nil
        }
    }
}
