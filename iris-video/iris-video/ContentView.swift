//
//  ContentView.swift
//  iris-video
//
//  Created by Yinka Adepoju on 28/5/24.
//

import SwiftUI
import AVKit

// Main view for video player
struct VideoPlayerView: UIViewControllerRepresentable {
    @Binding var isPlaying: Bool
    @Binding var videoURL: URL

    // Create AVPlayerViewController instance
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.showsPlaybackControls = false

        context.coordinator.player = player

        if isPlaying {
            player.play()
        }

        setupGestureRecognizers(on: playerViewController.view, context: context)

        // Restart video when it ends
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
            player.seek(to: .zero)
            if self.isPlaying {
                player.play()
            }
        }

        return playerViewController
    }

    // Update AVPlayerViewController instance
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player?.currentItem?.asset as? AVURLAsset != AVURLAsset(url: videoURL) {
            context.coordinator.stopPlayer()
            let player = AVPlayer(url: videoURL)
            uiViewController.player = player
            context.coordinator.player = player
            if isPlaying {
                player.play()
            }
        } else {
            if isPlaying {
                uiViewController.player?.play()
            } else {
                uiViewController.player?.pause()
            }
        }
    }

    // Create coordinator instance
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // Setup gesture recognizers
    private func setupGestureRecognizers(on view: UIView, context: Context) {
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture(_:)))
        tapGesture.numberOfTapsRequired = 1

        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTapGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2

        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = 0.5

        tapGesture.require(toFail: doubleTapGesture)

        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(doubleTapGesture)
        view.addGestureRecognizer(longPressGesture)
    }

    // Coordinator class for handling gestures and video control
    class Coordinator: NSObject {
        var player: AVPlayer?
        var longPressTimer: Timer?
        var isScrollingForward = false
        var initialLocation: CGPoint = .zero
        var speedMultiplier: Double = 2.0
        var isSeekInProgress = false
        var chaseTime = CMTime.zero

        func stopPlayer() {
            player?.pause()
            player = nil
        }

        // Handle tap gesture to play/pause
        @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            guard let player = player else { return }
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                player.play()
            }
        }

        // Handle double-tap gesture to seek forward/backward
        @objc func handleDoubleTapGesture(_ gesture: UITapGestureRecognizer) {
            guard let player = player else { return }
            let location = gesture.location(in: gesture.view)
            let viewWidth = gesture.view?.bounds.width ?? 1
            let currentTime = player.currentTime()
            let timeChange = CMTime(seconds: 10, preferredTimescale: 1)

            if location.x > viewWidth / 2 {
                let newTime = CMTimeAdd(currentTime, timeChange)
                seekSmoothly(to: newTime)
            } else {
                let newTime = CMTimeSubtract(currentTime, timeChange)
                seekSmoothly(to: newTime)
            }
        }

        // Handle long press gesture for fast scrolling
        @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
            guard let player = player else { return }
            let location = gesture.location(in: gesture.view)
            let viewWidth = gesture.view?.bounds.width ?? 1

            switch gesture.state {
            case .began:
                initialLocation = location
                isScrollingForward = location.x > viewWidth / 2
                startLongPressTimer()
            case .changed:
                adjustSpeedMultiplier(for: location, in: viewWidth)
            case .ended, .cancelled:
                stopLongPressTimer()
            default:
                break
            }
        }

        // Start timer for long press scrolling
        private func startLongPressTimer() {
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.scrollVideo()
            }
        }

        // Stop timer for long press scrolling
        private func stopLongPressTimer() {
            longPressTimer?.invalidate()
            longPressTimer = nil
            speedMultiplier = 2.0
        }

        // Adjust speed based on press location
        private func adjustSpeedMultiplier(for location: CGPoint, in viewWidth: CGFloat) {
            let deltaX = abs(location.x - initialLocation.x)
            let maxDeltaX = viewWidth / 2
            speedMultiplier = 2.0 + 8.0 * min(deltaX / maxDeltaX, 1.0)
        }

        // Scroll video based on speed multiplier
        private func scrollVideo() {
            guard let player = player else { return }
            let currentTime = player.currentTime()
            let timeChange = CMTime(seconds: 1 * speedMultiplier, preferredTimescale: 1)
            let newTime = isScrollingForward ? CMTimeAdd(currentTime, timeChange) : CMTimeSubtract(currentTime, timeChange)
            seekSmoothly(to: newTime)
        }

        // Seek smoothly to new time
        private func seekSmoothly(to time: CMTime) {
            if CMTimeCompare(time, chaseTime) != 0 {
                chaseTime = time
                if !isSeekInProgress {
                    trySeekToChaseTime()
                }
            }
        }

        // Attempt to seek to chase time
        private func trySeekToChaseTime() {
            guard let player = player, player.status == .readyToPlay else { return }
            actuallySeekToTime()
        }

        // Perform actual seek operation
        private func actuallySeekToTime() {
            guard let player = player else { return }
            isSeekInProgress = true
            let seekTimeInProgress = chaseTime

            player.seek(to: seekTimeInProgress, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                guard let self = self else { return }
                if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                    self.isSeekInProgress = false
                } else {
                    self.trySeekToChaseTime()
                }
            }
        }
    }
}

// Container view for video player with auto-start
struct VideoPlayerContainerView: View {
    @State private var isPlaying: Bool = true
    @State private var videoURL: URL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    @State private var videoSize: CGSize = .zero

    var body: some View {
        VStack {
            GeometryReader { geometry in
                VideoSizeReader(url: videoURL, videoSize: $videoSize)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        VideoPlayerView(isPlaying: $isPlaying, videoURL: $videoURL)
                            .aspectRatio(videoSize, contentMode: .fit)
                    )
                    .clipped()
            }
        }
        .onAppear {
            isPlaying = true // Auto-start video on appear
        }
    }
}

// Helper view to read video size
struct VideoSizeReader: UIViewRepresentable {
    let url: URL
    @Binding var videoSize: CGSize

    // Create UIView instance
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let tracks = asset.tracks(withMediaType: .video)
            if let track = tracks.first {
                let size = track.naturalSize.applying(track.preferredTransform)
                DispatchQueue.main.async {
                    self.videoSize = CGSize(width: abs(size.width), height: abs(size.height))
                }
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No update needed
    }
}

// Main content view
struct ContentView: View {
    var body: some View {
        VideoPlayerContainerView()
    }
}
