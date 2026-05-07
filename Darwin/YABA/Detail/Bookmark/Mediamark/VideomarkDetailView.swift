//
//  VideomarkDetailView.swift
//  YABA
//
//  Video bookmark detail using AVPlayerViewController native controls.
//

import AVFoundation
import AVKit
import SwiftUI

struct VideomarkDetailView: View {
    let bookmark: YabaBookmark
    let folderTint: Color

    @State
    private var player: AVPlayer?
    @State
    private var tempVideoURL: URL?

    var body: some View {
        GeometryReader { proxy in
            if let player {
                if player.status == .readyToPlay {
                    VideoPlayer(player: player)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ProgressView()
                }
            } else {
                ProgressView()
            }
        }
        .task(id: bookmark.bookmarkId) {
            await setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player?.replaceCurrentItem(with: nil)
            player = nil
            if let tempVideoURL {
                try? FileManager.default.removeItem(at: tempVideoURL)
                self.tempVideoURL = nil
            }
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func setupPlayer() async {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        if let tempVideoURL {
            try? FileManager.default.removeItem(at: tempVideoURL)
            self.tempVideoURL = nil
        }
        guard let data = bookmark.mediaDetail?.originalData, !data.isEmpty else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {}

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yaba-detail-\(bookmark.bookmarkId)-\(UUID().uuidString).mp4")
        do {
            try data.write(to: url, options: .atomic)
            tempVideoURL = url
            player = AVPlayer(url: url)
        } catch {
            player = nil
        }
        
        player?.allowsExternalPlayback = false
    }
}
