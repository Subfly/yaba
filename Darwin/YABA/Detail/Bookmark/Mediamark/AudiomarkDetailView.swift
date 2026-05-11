//
//  AudiomarkDetailView.swift
//  YABA
//
//  Audio bookmark detail with waveform scrubbing and transport controls.
//

import AVFoundation
import SwiftUI

struct AudiomarkDetailView: View {
    let bookmark: YabaBookmark
    let folderTint: Color

    @State
    private var player: AVAudioPlayer?
    @State
    private var tempAudioURL: URL?
    @State
    private var waveform: [CGFloat] = []
    @State
    private var currentTime: TimeInterval = 0
    @State
    private var duration: TimeInterval = 0
    @State
    private var isPlaying = false
    @State
    private var isScrubbing = false
    @State
    private var timer: Timer?

    private var playbackClockFont: Font {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .title2.weight(.medium)
        } else {
            return .body.weight(.medium)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let contentMaxWidth = AudiomarkDetailLayout.contentMaxWidth(containerWidth: geo.size.width)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                columnContent
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxHeight: .infinity)
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .task(id: bookmark.bookmarkId) {
            await setupAudio()
        }
        .onChange(of: bookmark.mediaDetail?.originalData?.count) { _, _ in
            Task { await setupAudio() }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            player?.stop()
            player = nil
            if let tempAudioURL {
                try? FileManager.default.removeItem(at: tempAudioURL)
                self.tempAudioURL = nil
            }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private var columnContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 52) {
                AudioWaveformScrubber(
                    mode: .playback,
                    amplitudes: waveform,
                    duration: max(duration, 0.001),
                    currentTime: currentTime,
                    barColor: folderTint,
                    passedBarColor: .secondary.opacity(0.4),
                    allowsScrubbing: true,
                    onScrubBegan: {
                        isScrubbing = true
                    },
                    onScrubChanged: { t in
                        currentTime = t
                        player?.currentTime = t
                    },
                    onScrubEnded: { t in
                        currentTime = t
                        player?.currentTime = t
                        isScrubbing = false
                    }
                )
                .frame(height: 120)

                HStack {
                    Text(formatElapsedClock(currentTime))
                        .font(playbackClockFont)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatElapsedClock(duration))
                        .font(playbackClockFont)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            HStack(spacing: 28) {
                controlButton(icon: "go-backward-5sec") {
                    seek(by: -5)
                }
                controlButton(icon: isPlaying ? "pause" : "play", isBig: true) {
                    togglePlayPause()
                }
                controlButton(icon: "go-forward-5sec") {
                    seek(by: 5)
                }
            }
            .padding(.bottom, 24)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func controlButton(
        icon: String,
        isBig: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            YabaIconView(bundleKey: icon)
                .frame(width: 26, height: 26)
                .foregroundStyle(.primary)
                .frame(
                    width: isBig ? 72 : 54,
                    height: isBig ? 72 : 54
                )
                .glassEffect(.regular.interactive())
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private func setupAudio() async {
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        if let tempAudioURL {
            try? FileManager.default.removeItem(at: tempAudioURL)
            self.tempAudioURL = nil
        }
        guard let data = bookmark.mediaDetail?.originalData, !data.isEmpty else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {}
        let ext = MediamarkManager.inferAudioFileExtension(from: data)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yaba-audio-detail-\(bookmark.bookmarkId)-\(UUID().uuidString).\(ext)")
        do {
            try data.write(to: url, options: .atomic)
            tempAudioURL = url
            waveform = AudioWaveformAnalyzer.bars(from: url)
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            self.player = player
            currentTime = 0
            duration = player.duration
            startTimer()
        } catch {
            self.player = nil
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            Task { @MainActor in
                guard let player else { return }
                if !isScrubbing {
                    currentTime = player.currentTime
                }
                if !player.isPlaying, isPlaying {
                    isPlaying = false
                }
            }
        }
    }

    private func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= max(0, duration - 0.01) {
                currentTime = 0
                player.currentTime = 0
            }
            player.play()
            isPlaying = true
        }
    }

    private func seek(by seconds: TimeInterval) {
        guard let player else { return }
        let target = min(max(0, player.currentTime + seconds), max(0, duration))
        player.currentTime = target
        currentTime = target
    }

    private func formatElapsedClock(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else {
            return Duration.zero.formatted(
                .time(pattern: .minuteSecond(padMinuteToLength: 2, roundFractionalSeconds: .down))
            )
        }
        let sec = Int64(max(0, seconds).rounded(.towardZero))
        let d = Duration(secondsComponent: sec, attosecondsComponent: 0)
        if sec >= 3600 {
            return d.formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2, roundFractionalSeconds: .down)))
        }
        return d.formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2, roundFractionalSeconds: .down)))
    }
}

// MARK: - Column width (iPhone full width; iPad / Mac constrained)

private enum AudiomarkDetailLayout {
    static func contentMaxWidth(containerWidth: CGFloat) -> CGFloat {
        #if targetEnvironment(macCatalyst)
        containerWidth * 0.7
        #elseif os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return containerWidth * 0.9
        default:
            return containerWidth
        }
        #else
        containerWidth
        #endif
    }
}
