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
}

#endif
