//
//  Player.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 5/4/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation

@MainActor
final class Player {
    // MARK: Lifecycle

    deinit {
        rateObservation?.invalidate()
        if let playbackEndedObserver {
            NotificationCenter.default.removeObserver(playbackEndedObserver)
        }
    }

    init(url: URL) {
        asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: url.isFileURL])
        playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .spectral
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = !url.isFileURL

        playbackEndedObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.onPlaybackEnded?()
            }
        }

        rateObservation = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] _, change in
            if let rate = change.newValue {
                guard let self else { return }
                Task {
                    await self.onRateChanged?(rate)
                }
            }
        }
    }

    // MARK: Internal

    var onRateChanged: (@Sendable @MainActor (Float) -> Void)?
    var onPlaybackEnded: (@Sendable @MainActor () -> Void)?

    let playerItem: AVPlayerItem

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    // MARK: Internal helpers (read-only)

    var isPlaying: Bool {
        player.rate != 0
    }

    func play(rate: Float) {
        if asset.url.isFileURL {
            player.playImmediately(atRate: rate)
        } else {
            player.rate = rate
        }
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func setRate(_ rate: Float) {
        player.rate = rate
    }

    func seek(to timeInSeconds: TimeInterval, rate: Float) {
        pause()
        player.seek(to: timeInSeconds)
        play(rate: rate)
    }

    // MARK: Private

    private let asset: AVURLAsset
    private let player: AVPlayer
    private var playbackEndedObserver: NSObjectProtocol?

    private var rateObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }
}

private extension AVPlayer {
    func seek(to timeInSeconds: TimeInterval) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1000)
        seek(to: time)
    }
}
