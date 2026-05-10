//
//  PDFPreviewExtractor.swift
//  YABACore
//
//  First-page preview PNG extraction from PDFKit (bookmark card image only; no PDF metadata persistence).
//

import Foundation
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

public enum PDFPreviewExtractor {
    public static func firstPagePNG(fromFile url: URL, renderScale: CGFloat = 1.2) -> Data? {
        guard let document = PDFDocument(url: url) else { return nil }
        return firstPagePNG(document: document, renderScale: renderScale)
    }

    public static func firstPagePNG(from data: Data, renderScale: CGFloat = 1.2) -> Data? {
        guard let document = PDFDocument(data: data) else { return nil }
        return firstPagePNG(document: document, renderScale: renderScale)
    }

    public static func firstPagePNG(document: PDFDocument, renderScale: CGFloat = 1.2) -> Data? {
        guard let page = document.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let w = max(1, bounds.width * renderScale)
        let h = max(1, bounds.height * renderScale)
        let size = CGSize(width: w, height: h)

        let image = page.thumbnail(of: size, for: .mediaBox)
#if canImport(UIKit)
        return image.pngData()
#elseif os(macOS)
        return pngData(from: image)
#else
        return nil
#endif
    }

#if os(macOS)
    private static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
#endif
}
