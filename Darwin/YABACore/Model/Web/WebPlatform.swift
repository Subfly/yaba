//
//  WebPlatform.swift
//  YABACore
//
//  Query parameter for bundled `editor.html` / `canvas.html` theme bootstrap (see yaba-web-components `parseUrlParams`).
//

import Foundation

/// Passed as `?platform=`; `compose` is a legacy alias mapped to the Android palette in the web bundle.
public enum WebPlatform: String, Sendable, Codable {
    case darwin
    case compose
}
