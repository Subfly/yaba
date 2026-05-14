//
//  YabaInputAccessoryWKWebView.swift
//  YABACore
//

#if os(iOS)

import UIKit
import WebKit

/// `WKWebView` whose keyboard accessory is fully controlled by assigning ``accessoryView``
/// (replaces the default assistant strip WebKit would attach).
public final class YabaInputAccessoryWKWebView: WKWebView {
    public var accessoryView: UIView?

    public override var inputAccessoryView: UIView? {
        accessoryView
    }

    #if targetEnvironment(macCatalyst)
    /// Routed from `WKWebViewRuntime` so ⌘C / ⌘V / ⌘X reach CodeMirror via `window.__yabaTriggerNative*` + pasteboard bridge.
    public var catalystPerformCopy: (() -> Void)?
    public var catalystPerformPaste: (() -> Void)?
    public var catalystPerformCut: (() -> Void)?

    public override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(yabaCatalystCopy(_:))),
            UIKeyCommand(input: "v", modifierFlags: .command, action: #selector(yabaCatalystPaste(_:))),
            UIKeyCommand(input: "x", modifierFlags: .command, action: #selector(yabaCatalystCut(_:))),
        ]
    }

    @objc private func yabaCatalystCopy(_ sender: UICommand) {
        catalystPerformCopy?()
    }

    @objc private func yabaCatalystPaste(_ sender: UICommand) {
        catalystPerformPaste?()
    }

    @objc private func yabaCatalystCut(_ sender: UICommand) {
        catalystPerformCut?()
    }
    #endif
}

#endif
