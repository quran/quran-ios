//
//  Player.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 5/4/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation

protocol PlayerDelegate: class {
    func onRateChanged(to rate: Float)
}

class Player {

    weak var delegate: PlayerDelegate?

    private let asset: AVURLAsset
    let playerItem: AVPlayerItem
    private let player: AVPlayer

    private var rateObservation: NSKeyValueObservation? {
        didSet { oldValue?.invalidate() }
    }

    deinit {
        rateObservation?.invalidate()
    }

    init(url: URL) {
        asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        rateObservation = player.observe(\AVPlayer.rate, options: [.new]) { [weak self] (_, change) in
            if let rate = change.newValue {
                self?.delegate?.onRateChanged(to: rate)
            }
        }
    }

    var currentTime: TimeInterval {
        return player.currentTime().seconds
    }

    var duration: TimeInterval {
        return asset.duration.seconds
    }

    var rate: Float {
        return player.rate
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func seek(to timeInSeconds: TimeInterval) {
        pause()
        player.seek(to: timeInSeconds)
        play()
    }
}

private extension AVPlayer {
    func seek(to timeInSeconds: TimeInterval) {
        let time = CMTime(seconds: timeInSeconds, preferredTimescale: 1_000)
        seek(to: time)
    }
}
