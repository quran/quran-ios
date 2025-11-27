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
    }

    init(url: URL) {
        asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        playerItem = AVPlayerItem(asset: asset)
        playerItem.audioTimePitchAlgorithm = .spectral
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false

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

    let playerItem: AVPlayerItem

    var currentTime: TimeInterval {
        player.currentTime().seconds
    }

    var duration: TimeInterval {
        asset.duration.seconds
    }

    func play() {
        player.playImmediately(atRate: currentRate)
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }
    
    func setRate(_ rate: Float) {
        currentRate = rate
        if player.rate != 0 {
            player.rate = rate
        }
    }

    func seek(to timeInSeconds: TimeInterval) {
        pause()
        player.seek(to: timeInSeconds)
        play()
    }

    // MARK: Internal helpers (read-only)

    var isPlaying: Bool {
        player.rate != 0
    }

    /// The effective rate to use for scheduling:
    /// - if playing, use the live AVPlayer rate
    /// - if paused, fall back to the last requested rate (currentRate)
    var effectiveRate: Float {
        player.rate != 0 ? player.rate : currentRate
    }

    // MARK: Private

    private let asset: AVURLAsset
    private let player: AVPlayer
    private var currentRate: Float = 1.0

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
