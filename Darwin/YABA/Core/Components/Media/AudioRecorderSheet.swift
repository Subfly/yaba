//
//  AudioRecorderSheet.swift
//  YABA
//
//  Custom WAV recorder inspired by voice memos.
//

import AVFoundation
import SwiftUI

struct AudioRecorderSheet: View {
    let onDismiss: () -> Void
    /// WAV bytes, extension (always `wav`), recorder temp file path when available.
    let onDone: (Data, String, String?) -> Void

    @State
    private var phase: RecorderPhase = .idle
    @State
    private var recorder: AVAudioRecorder?
    @State
    private var player: AVAudioPlayer?
    @State
    private var recordingURL: URL?
    @State
    private var liveAmplitudes: [CGFloat] = []
    @State
    private var sampledAmplitudes: [CGFloat] = []
    @State
    private var currentTime: TimeInterval = 0
    @State
    private var duration: TimeInterval = 0
    @State
    private var isPlayingPreview = false
    @State
    private var meterTimer: Timer?
    @State
    private var playbackTimer: Timer?
    @State
    private var pendingOutputData: Data?

    var body: some View {
        VStack(spacing: 18) {
            AudioWaveformScrubber(
                mode: phase == .recording ? .recordingLive : .playback,
                amplitudes: phase == .recorded ? sampledAmplitudes : liveAmplitudes,
                duration: max(duration, 0.001),
                currentTime: currentTime,
                barColor: phase == .recorded ? .red : .primary,
                passedBarColor: .secondary.opacity(0.4),
                allowsScrubbing: phase == .recorded,
                onScrubBegan: {
                    if isPlayingPreview {
                        player?.pause()
                        isPlayingPreview = false
                    }
                },
                onScrubChanged: { newTime in
                    currentTime = newTime
                    player?.currentTime = newTime
                },
                onScrubEnded: { newTime in
                    currentTime = newTime
                    player?.currentTime = newTime
                }
            )
            .frame(height: 84)
            .padding(.horizontal, 16)

            controls
                .padding(.bottom, 14)
        }
        .onDisappear {
            tearDown()
        }
        .navigationTitle("Record Audio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onDismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    finishRecording()
                }
                .disabled(phase != .recorded || pendingOutputData == nil)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch phase {
        case .idle:
            recordButton
                .transition(.scale.combined(with: .opacity))
        case .recording:
            stopRecordingButton
                .transition(.scale.combined(with: .opacity))
        case .recorded:
            HStack(spacing: 24) {
                materialIconButton(icon: "redo") {
                    redoRecording()
                }
                materialIconButton(icon: isPlayingPreview ? "pause" : "play") {
                    togglePreviewPlayback()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var recordButton: some View {
        Button {
            beginRecording()
        } label: {
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 64, height: 64)
                .glassEffect(.regular.tint(.red.opacity(0.8)).interactive())
        }
        .buttonStyle(.plain)
        .animation(.smooth, value: phase)
    }

    private var stopRecordingButton: some View {
        Button {
            stopRecording()
        } label: {
            YabaIconView(bundleKey: "stop")
                .frame(width: 28, height: 28)
                .foregroundStyle(.red)
                .frame(width: 64, height: 64)
                .background {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .animation(.smooth, value: phase)
    }

    @ViewBuilder
    private func materialIconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            YabaIconView(bundleKey: icon)
                .frame(width: 26, height: 26)
                .foregroundStyle(.primary)
                .frame(width: 54, height: 54)
                .background {
                    Circle().fill(.ultraThinMaterial)
                }
                .glassEffect(.regular.interactive())
        }
        .buttonStyle(.plain)
    }

    private func beginRecording() {
        let permissionHandler: (Bool) -> Void = { granted in
            guard granted else { return }
            Task { @MainActor in
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(
                        .playAndRecord,
                        mode: .default,
                        options: [.defaultToSpeaker, .allowBluetoothHFP]
                    )
                    try session.setActive(true)

                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("yaba-audio-\(UUID().uuidString).wav")
                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                        AVSampleRateKey: 44_100,
                        AVNumberOfChannelsKey: 1,
                        AVLinearPCMBitDepthKey: 16,
                        AVLinearPCMIsBigEndianKey: false,
                        AVLinearPCMIsFloatKey: false,
                    ]
                    let recorder = try AVAudioRecorder(url: url, settings: settings)
                    recorder.isMeteringEnabled = true
                    recorder.record()

                    self.recordingURL = url
                    self.recorder = recorder
                    self.player = nil
                    self.currentTime = 0
                    self.duration = 0
                    self.liveAmplitudes = []
                    self.sampledAmplitudes = []
                    pendingOutputData = nil
                    withAnimation(.smooth) { phase = .recording }
                    startMeterTimer()
                } catch {}
            }
        }

        AVAudioApplication.requestRecordPermission(completionHandler: permissionHandler)
    }

    private func stopRecording() {
        guard let recorder else { return }
        recorder.stop()
        meterTimer?.invalidate()
        meterTimer = nil
        duration = recorder.currentTime
        currentTime = 0
        if let url = recordingURL {
            sampledAmplitudes = AudioWaveformAnalyzer.bars(from: url)
            pendingOutputData = try? Data(contentsOf: url)
        }
        withAnimation(.smooth) { phase = .recorded }
    }

    private func redoRecording() {
        player?.stop()
        isPlayingPreview = false
        playbackTimer?.invalidate()
        playbackTimer = nil
        recorder?.stop()
        recorder = nil
        if let recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
        currentTime = 0
        duration = 0
        liveAmplitudes = []
        sampledAmplitudes = []
        pendingOutputData = nil
        withAnimation(.smooth) { phase = .idle }
    }

    private func togglePreviewPlayback() {
        guard let url = recordingURL else { return }
        do {
            if player == nil {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
            }
            guard let player else { return }
            if isPlayingPreview {
                player.pause()
                isPlayingPreview = false
                playbackTimer?.invalidate()
                playbackTimer = nil
            } else {
                if currentTime >= max(0, duration - 0.01) {
                    currentTime = 0
                    player.currentTime = 0
                }
                player.play()
                isPlayingPreview = true
                startPlaybackTimer()
            }
        } catch {}
    }

    private func finishRecording() {
        guard let data = pendingOutputData, !data.isEmpty else { return }
        onDone(data, "wav", recordingURL?.path)
        onDismiss()
    }

    private func startMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                guard let recorder else { return }
                recorder.updateMeters()
                let db = recorder.averagePower(forChannel: 0)
                let normalized = max(0.02, CGFloat(pow(10, db / 20)))
                liveAmplitudes.append(normalized)
                if liveAmplitudes.count > 500 {
                    liveAmplitudes.removeFirst(liveAmplitudes.count - 500)
                }
                currentTime = recorder.currentTime
                duration = recorder.currentTime
            }
        }
    }

    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            Task { @MainActor in
                guard let player else { return }
                currentTime = player.currentTime
                duration = max(duration, player.duration)
                if !player.isPlaying {
                    isPlayingPreview = false
                    playbackTimer?.invalidate()
                    playbackTimer = nil
                }
            }
        }
    }

    private func tearDown() {
        meterTimer?.invalidate()
        meterTimer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        recorder?.stop()
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private enum RecorderPhase {
    case idle
    case recording
    case recorded
}
