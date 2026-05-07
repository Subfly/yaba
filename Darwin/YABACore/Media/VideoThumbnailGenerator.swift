//
//  VideoThumbnailGenerator.swift
//  YABACore
//
//  PNG thumbnail extraction from movie bytes for preview payloads (lossless raster).
//

import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum VideoThumbnailGenerator {
    /// A PNG thumbnail at a random instant in the movie (for list cards / creation preview).
    public static func randomPNGThumbnailData(fromMovieFile url: URL) throws -> Data? {
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let seconds = CMTimeGetSeconds(asset.duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        let t = Double.random(in: 0.05 ... max(0.05, seconds * 0.95))
        let time = CMTime(seconds: t, preferredTimescale: 600)
        let cgImage = try gen.copyCGImage(at: time, actualTime: nil)
        return pngData(from: cgImage)
    }

    public static func randomPNGThumbnailData(fromMovieBytes data: Data, fileExtension: String) throws -> Data? {
        let ext = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "mp4"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yaba-thumb-src-\(UUID().uuidString)")
            .appendingPathExtension(ext)
        try data.write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }
        return try randomPNGThumbnailData(fromMovieFile: url)
    }

    private static func pngData(from cgImage: CGImage) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}
