//
//  ColorPickerPresentationPolicy.swift
//  YABA
//
//  Sheet on iPhone; popover anchored to the trigger on iPad and Mac Catalyst.
//

import SwiftUI

enum ColorPickerPresentationPolicy {
    /// macOS Catalyst and iPad use an anchored popover; iPhone keeps a sheet.
    static var prefersPopover: Bool {
        switch DeviceType.current {
        case .computer, .tablet:
            true
        case .phone, .unknown:
            false
        }
    }

    /// Binding for `.sheet`: only active when popover is not used.
    static func sheetBinding(_ presented: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { presented.wrappedValue && !prefersPopover },
            set: { newValue in
                if !newValue {
                    presented.wrappedValue = false
                }
            }
        )
    }

    /// Binding for `.popover`: only active on iPad / Catalyst.
    static func popoverBinding(_ presented: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { presented.wrappedValue && prefersPopover },
            set: { newValue in
                if !newValue {
                    presented.wrappedValue = false
                }
            }
        )
    }
}
