//
//  WebLoadState.swift
//  YABACore
//
//  Parity with Compose `WebLoadState`.
//

import Foundation

/// Result of the web shell’s first content load (`shellLoad` host event).
public enum WebShellLoadResult: Sendable {
    case loaded
    case error
}

public enum WebLoadState: Sendable {
    case idle
    case loading(progressFraction: Float?)
    case pageFinished
    case bridgeReady
    case rendererCrashed
}
