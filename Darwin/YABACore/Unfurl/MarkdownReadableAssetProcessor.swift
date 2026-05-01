//
//  MarkdownReadableAssetProcessor.swift
//  YABACore
//
//  Parses readable Markdown, downloads HTTP(S) images in first-seen order, and rewrites destinations
//  to stable `yaba-asset://<assetId>` references (no `../assets/...` paths in stored content).
//

import Foundation

public enum MarkdownReadableAssetProcessor {
    public static func process(markdown: String, baseURL: String) async -> ReadableUnfurl {
        // TODO: IMPLEMENT HERE CORRECTLY
        return ReadableUnfurl(markdown: "", assets: [])
    }
}
