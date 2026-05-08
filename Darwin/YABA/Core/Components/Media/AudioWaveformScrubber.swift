//
//  AudioWaveformScrubber.swift
//  YABA
//
//  Bar-based waveform rendering for live recording and playback scrubbing.
//

import AVFoundation
import SwiftUI

enum AudioWaveformAnalyzer {
    static func bars(from audioURL: URL, targetBarCount: Int = 220) -> [CGFloat] {
        guard targetBarCount > 0 else { return [] }
        guard let file = try? AVAudioFile(forReading: audioURL) else {
            return []
        }
        let frameCount = AVAudioFrameCount(file.length)
        guard frameCount > 0 else { return [] }
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: frameCount
        ) else {
            return []
        }
        do {
            try file.read(into: buffer)
        } catch {
            return []
        }
        guard let samples = buffer.floatChannelData?.pointee else {
            return []
        }
        let sampleCount = Int(buffer.frameLength)
        guard sampleCount > 0 else { return [] }

        let window = max(1, sampleCount / targetBarCount)
        var result: [CGFloat] = []
        result.reserveCapacity(targetBarCount)
        var peak: Float = 0
        var idx = 0
        while idx < sampleCount {
            let end = min(sampleCount, idx + window)
            var localPeak: Float = 0
            var cursor = idx
            while cursor < end {
                let v = abs(samples[cursor])
                if v > localPeak { localPeak = v }
                cursor += 1
            }
            peak = max(peak, localPeak)
            result.append(CGFloat(localPeak))
            idx += window
        }
        guard peak > 0 else { return [] }
        return result.map { max(0.02, $0 / CGFloat(peak)) }
    }
}

enum AudioWaveformMode {
    /// Live recorder mode: bars fill from far-right toward center/left.
    case recordingLive
    /// Playback mode: bars scroll under center; bars that passed center get a different color.
    case playback
}

struct AudioWaveformScrubber: View {
    let mode: AudioWaveformMode
    let amplitudes: [CGFloat]
    let duration: TimeInterval
    let currentTime: TimeInterval
    let barColor: Color
    let passedBarColor: Color
    let allowsScrubbing: Bool
    var onScrubBegan: (() -> Void)? = nil
    var onScrubChanged: (TimeInterval) -> Void
    var onScrubEnded: (TimeInterval) -> Void

    @State
    private var isDragging = false
    @State
    private var lastScrubTime: TimeInterval = 0

    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private let amplitudeVisualBoost: CGFloat = 1.75

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            switch mode {
            case .recordingLive:
                recordingBars(width: width, height: height)
            case .playback:
                playbackBars(width: width, height: height)
            }
        }
    }

    @ViewBuilder
    private func recordingBars(width: CGFloat, height: CGFloat) -> some View {
        let bars = amplitudes
        let regionWidth = width
        let step = barWidth + barSpacing
        let maxBarsInRegion = max(1, Int(regionWidth / step))
        let visibleBars = Array(bars.suffix(maxBarsInRegion))
        let contentWidth = CGFloat(visibleBars.count) * step
        let startX = max(0, regionWidth - contentWidth)

        ZStack(alignment: .leading) {
            ForEach(Array(visibleBars.enumerated()), id: \.offset) { index, amp in
                let boosted = min(1, amp * amplitudeVisualBoost)
                Capsule()
                    .fill(barColor.opacity(0.92))
                    .frame(width: barWidth, height: max(6, boosted * (height - 8)))
                    .offset(x: startX + CGFloat(index) * step)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(width: width, height: height, alignment: .leading)
        .clipped()
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func playbackBars(width: CGFloat, height: CGFloat) -> some View {
        let step = barWidth + barSpacing
        let visibleCount = max(1, Int(width / step))
        let bars = normalizeToVisibleCount(amplitudes, targetCount: visibleCount)
        let listenedFraction: CGFloat = {
            guard duration > 0 else { return 0 }
            return clamp(CGFloat(currentTime / duration), min: 0, max: 1)
        }()
        let listenedIndex = Int(CGFloat(max(0, bars.count - 1)) * listenedFraction)

        ZStack(alignment: .leading) {
            ForEach(Array(bars.enumerated()), id: \.offset) { index, amp in
                let x = CGFloat(index) * step
                let boosted = min(1, amp * amplitudeVisualBoost)
                Capsule()
                    .fill(index <= listenedIndex ? barColor : passedBarColor)
                    .frame(width: barWidth, height: max(6, boosted * (height - 8)))
                    .offset(x: x)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .animation(.smooth, value: listenedIndex)
        .frame(width: width, height: height, alignment: .leading)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    guard allowsScrubbing else { return }
                    if !isDragging {
                        isDragging = true
                        onScrubBegan?()
                    }
                    let x = clamp(value.location.x, min: 0, max: width)
                    let fraction = width > 0 ? x / width : 0
                    let seconds = TimeInterval(fraction) * duration
                    lastScrubTime = seconds
                    onScrubChanged(seconds)
                }
                .onEnded { _ in
                    guard allowsScrubbing else { return }
                    isDragging = false
                    onScrubEnded(lastScrubTime)
                }
        )
    }

    private func normalizeToVisibleCount(_ source: [CGFloat], targetCount: Int) -> [CGFloat] {
        guard targetCount > 0 else { return [] }
        guard !source.isEmpty else { return [] }
        if source.count == targetCount {
            return source
        }
        var output: [CGFloat] = []
        output.reserveCapacity(targetCount)
        for i in 0..<targetCount {
            let fraction = targetCount > 1 ? CGFloat(i) / CGFloat(targetCount - 1) : 0
            let sourceIndex = Int(round(fraction * CGFloat(max(0, source.count - 1))))
            output.append(source[min(max(0, sourceIndex), source.count - 1)])
        }
        return output
    }

    private func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        Swift.min(max, Swift.max(min, value))
    }
}
