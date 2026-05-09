//
//  CoreToastOverlayView.swift
//  YABA
//
//  Renders `CoreToastManager.shared.visibleToasts` for global hints.
//

import Observation
import SwiftUI
import UIKit

struct CoreToastOverlayView: View {
    /// Vertical travel when hiding (matches slide-from-bottom language).
    private let toastSlideOutOffset: CGFloat = 36

    @Bindable
    private var manager = CoreToastManager.shared

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 8) {
            ForEach(manager.visibleToasts) { toast in
                toastContainer(for: toast)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func toastContainer(for toast: ToastItem) -> some View {
        Group {
            if horizontalSizeClass == .regular {
                HStack {
                    Spacer(minLength: 0)
                    toastRow(toast)
                        .frame(maxWidth: 400)
                    Spacer(minLength: 0)
                }
            } else {
                toastRow(toast)
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
            )
        )
    }

    private func toastRow(_ toast: ToastItem) -> some View {
        let palette = toastPalette(for: toast.iconType)
        let stripWidth: CGFloat = toast.iconType == .none ? 12 : 60

        return HStack(spacing: 0) {
            ZStack {
                palette.accentColor
                if toast.iconType != .none {
                    YabaIconView(bundleKey: toast.iconType.iconAssetName)
                        .foregroundStyle(palette.iconColor)
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: stripWidth)
            .frame(maxHeight: .infinity)

            HStack(spacing: 8) {
                Text(toast.message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let acceptLabel = toast.acceptText {
                    Button {
                        manager.accept(id: toast.id)
                    } label: {
                        Text(acceptLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(palette.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(toastSurfaceColor)
        }
        .frame(height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 12, x: 0, y: 4)
        .offset(y: toast.isVisible ? 0 : toastSlideOutOffset)
        .opacity(toast.isVisible ? 1 : 0)
        .animation(
            .easeInOut(duration: Constants.toastAnimationDurationSeconds),
            value: toast.isVisible
        )
        .allowsHitTesting(toast.isVisible)
    }

    /// Solid surface for the message/action side (Compose: `surfaceContainerLow` from theme).
    private var toastSurfaceColor: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    private func toastPalette(for iconType: ToastIconType) -> ToastPalette {
        let yaba: YabaColor
        switch iconType {
        case .warning:
            yaba = .orange
        case .success:
            yaba = .green
        case .hint:
            yaba = .blue
        case .error:
            yaba = .red
        case .none:
            yaba = .gray
        }
        let hex = yaba.canonicalHexDigits ?? "8e8e93"
        return ToastPalette(
            accentColor: colorFromPaletteHexDigits(hex),
            iconColor: .white
        )
    }
}

// MARK: - Palette

private struct ToastPalette {
    let accentColor: Color
    let iconColor: Color
}

/// Parity with Compose `YabaColor.iconTintArgb()` via `YabaColor.canonicalHexDigits`.
private func colorFromPaletteHexDigits(_ hex: String) -> Color {
    var value: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&value)
    let r = Double((value >> 16) & 0xFF) / 255
    let g = Double((value >> 8) & 0xFF) / 255
    let b = Double(value & 0xFF) / 255
    return Color(red: r, green: g, blue: b)
}
