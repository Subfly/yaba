//
//  VideomarkDetailView.swift
//  YABA
//
//  Video bookmark detail with custom transport controls and timeline scrubbing.
//

import AVFoundation
import SwiftUI

struct VideomarkDetailView: View {
    let bookmark: YabaBookmark
    let folderTint: Color

    @State
    private var player: AVPlayer?
    @State
    private var tempVideoURL: URL?
    @State
    private var currentTime: TimeInterval = 0
    @State
    private var duration: TimeInterval = 0
    @State
    private var isPlaying = false
    @State
    private var isScrubbing = false
    @State
    private var isPreparing = true
    @State
    private var timelineBars: [CGFloat] = Array(repeating: 0.4, count: 220)
    @State
    private var timeObserver: Any?
    @State
    private var playbackEndObserver: NSObjectProtocol?
    @State
    private var videoAspectRatio: CGFloat = 16 / 9
    @State
    private var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    private var playbackClockFont: Font {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .title2.weight(.medium)
        } else {
            return .body.weight(.medium)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let contentMaxWidth = VideomarkDetailLayout.contentMaxWidth(containerWidth: geo.size.width)
            HStack(spacing: 0) {
                Spacer()
                columnContent
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxHeight: .infinity)
                Spacer()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .task(id: bookmark.bookmarkId) {
            await setupPlayer()
        }
        .onChange(of: bookmark.mediaDetail?.originalData?.count) { _, _ in
            Task { await setupPlayer() }
        }
        .onDisappear {
            cleanupPlayer()
        }
    }

    private var columnContent: some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 0) {
                ZStack {
                    videoSurface
                    overlayControls
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(spacing: 52) {
                AudioWaveformScrubber(
                    mode: .playback,
                    amplitudes: timelineBars,
                    duration: max(duration, 0.001),
                    currentTime: currentTime,
                    barColor: folderTint,
                    passedBarColor: .secondary.opacity(0.4),
                    allowsScrubbing: true,
                    onScrubBegan: {
                        isScrubbing = true
                    },
                    onScrubChanged: { t in
                        seek(to: t)
                    },
                    onScrubEnded: { t in
                        seek(to: t)
                        isScrubbing = false
                    }
                )
                .frame(height: 60)

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
                .padding(
                    .bottom,
                    UIDevice.current.userInterfaceIdiom == .pad ? 48 : 12
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if UIDevice.current.userInterfaceIdiom == .pad {
                Spacer()
            }
        }
    }

    private var videoSurface: some View {
        ZStack {
            if let player {
                VideoPlayerLayerView(
                    player: player,
                    videoGravity: videoGravity
                ).frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isPreparing {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(videoAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var overlayControls: some View {
        VStack {
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
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 16)
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
                .frame(width: isBig ? 72 : 54, height: isBig ? 72 : 54)
                .glassEffect(.regular.interactive())
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }

    private func setupPlayer() async {
        cleanupPlayer(removeTempFile: true, deactivateSession: false)
        isPreparing = true

        guard let data = bookmark.mediaDetail?.originalData, !data.isEmpty else {
            isPreparing = false
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {}

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yaba-video-detail-\(bookmark.bookmarkId)-\(UUID().uuidString).mp4")

        do {
            try data.write(to: url, options: .atomic)
            tempVideoURL = url

            let player = AVPlayer(url: url)
            player.allowsExternalPlayback = false
            self.player = player
            currentTime = 0
            isPlaying = false
            observePlayerTime(for: player)

            let asset = AVURLAsset(url: url)
            if let loadedDuration = try? await asset.load(.duration) {
                let seconds = loadedDuration.seconds
                duration = seconds.isFinite ? max(0, seconds) : 0
            } else {
                duration = 0
            }
            await updateVideoPresentation(from: asset)
            timelineBars = await makeTimelineBars(from: asset)
        } catch {
            self.player = nil
            duration = 0
            timelineBars = fallbackTimelineBars()
        }

        isPreparing = false
    }

    private func observePlayerTime(for player: AVPlayer) {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        let interval = CMTime(seconds: 0.03, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            if !isScrubbing {
                let seconds = time.seconds
                currentTime = seconds.isFinite ? max(0, seconds) : 0
            }
            isPlaying = player.timeControlStatus == .playing
        }

        if let playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
            self.playbackEndObserver = nil
        }

        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
            currentTime = duration
        }
    }

    private func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= max(0, duration - 0.01) {
                seek(to: 0)
            }
            player.play()
            isPlaying = true
        }
    }

    private func seek(by seconds: TimeInterval) {
        let target = min(max(0, currentTime + seconds), max(0, duration))
        seek(to: target)
    }

    private func seek(to seconds: TimeInterval) {
        guard let player else { return }
        let target = min(max(0, seconds), max(0, duration))
        currentTime = target
        let time = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func cleanupPlayer(removeTempFile: Bool = true, deactivateSession: Bool = true) {
        player?.pause()
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
            self.playbackEndObserver = nil
        }
        player?.replaceCurrentItem(with: nil)
        player = nil
        isPlaying = false
        videoAspectRatio = 16 / 9
        videoGravity = .resizeAspectFill

        if removeTempFile, let tempVideoURL {
            try? FileManager.default.removeItem(at: tempVideoURL)
            self.tempVideoURL = nil
        }

        if deactivateSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func makeTimelineBars(from asset: AVAsset, targetBarCount: Int = 220) async -> [CGFloat] {
        guard targetBarCount > 0 else { return [] }

        do {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            guard let audioTrack = audioTracks.first else {
                return fallbackTimelineBars(count: targetBarCount)
            }

            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsBigEndianKey: false,
            ]

            let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
            let reader = try AVAssetReader(asset: asset)
            guard reader.canAdd(output) else {
                return fallbackTimelineBars(count: targetBarCount)
            }
            reader.add(output)

            guard reader.startReading() else {
                return fallbackTimelineBars(count: targetBarCount)
            }

            var peaks: [CGFloat] = []
            let sampleWindow = 1024

            while reader.status == .reading {
                guard let sampleBuffer = output.copyNextSampleBuffer() else { break }
                defer { CMSampleBufferInvalidate(sampleBuffer) }

                guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
                let byteLength = CMBlockBufferGetDataLength(blockBuffer)
                guard byteLength > 0 else { continue }

                var data = Data(count: byteLength)
                let copyStatus = data.withUnsafeMutableBytes { rawBuffer -> OSStatus in
                    guard let baseAddress = rawBuffer.baseAddress else {
                        return -1
                    }
                    return CMBlockBufferCopyDataBytes(
                        blockBuffer,
                        atOffset: 0,
                        dataLength: byteLength,
                        destination: baseAddress
                    )
                }
                guard copyStatus == 0 else { continue }

                data.withUnsafeBytes { rawBuffer in
                    let samples = rawBuffer.bindMemory(to: Float.self)
                    guard !samples.isEmpty else { return }

                    var index = 0
                    while index < samples.count {
                        let end = min(samples.count, index + sampleWindow)
                        var localPeak: Float = 0
                        var cursor = index
                        while cursor < end {
                            localPeak = max(localPeak, abs(samples[cursor]))
                            cursor += 1
                        }
                        peaks.append(CGFloat(localPeak))
                        index += sampleWindow
                    }
                }
            }

            guard !peaks.isEmpty else {
                return fallbackTimelineBars(count: targetBarCount)
            }

            let maxPeak = peaks.max() ?? 0
            guard maxPeak > 0 else {
                return fallbackTimelineBars(count: targetBarCount)
            }

            let normalized = peaks.map { max(0.02, $0 / maxPeak) }
            return resampleBars(normalized, targetCount: targetBarCount)
        } catch {
            return fallbackTimelineBars(count: targetBarCount)
        }
    }

    private func fallbackTimelineBars(count: Int = 220) -> [CGFloat] {
        guard count > 0 else { return [] }
        return Array(repeating: 0.2, count: count)
    }

    private func resampleBars(_ source: [CGFloat], targetCount: Int) -> [CGFloat] {
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

    @MainActor
    private func updateVideoPresentation(from asset: AVURLAsset) async {
        do {
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            guard let track = videoTracks.first else { return }
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformedSize = naturalSize.applying(transform)
            let width = abs(transformedSize.width)
            let height = abs(transformedSize.height)
            guard width > 0, height > 0 else { return }

            videoAspectRatio = width / height
            videoGravity = width >= height ? .resizeAspectFill : .resizeAspect
        } catch {
            videoAspectRatio = 16 / 9
            videoGravity = .resizeAspectFill
        }
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

private struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = videoGravity
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = videoGravity
    }

    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - Column width (iPhone full width; iPad / Mac constrained)

private enum VideomarkDetailLayout {
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
