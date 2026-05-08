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

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
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
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            HStack(spacing: 28) {
                controlButton(icon: "go-backward-5sec") {
                    seek(by: -5)
                }
                controlButton(icon: isPlaying ? "pause" : "play") {
                    togglePlayPause()
                }
                controlButton(icon: "go-forward-5sec") {
                    seek(by: 5)
                }
            }
            .animation(nil, value: isPlaying)
            .padding(.bottom, 24)
        }
        .task(id: bookmark.bookmarkId) {
            await setupAudio()
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
        }
    }

    @ViewBuilder
    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            YabaIconView(bundleKey: icon)
                .frame(width: 26, height: 26)
                .foregroundStyle(.primary)
                .frame(width: 54, height: 54)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                .ifAvailableiOS26Glass()
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
}

private extension View {
    @ViewBuilder
    func ifAvailableiOS26Glass() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.interactive())
        } else {
            self
        }
    }
}
