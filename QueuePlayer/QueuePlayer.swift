//
//  QueuePlayer.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/23/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation
import MediaPlayer
import VFoundation

public protocol QueuePlayerDelegate: class {
    func onPlaybackEnded()
    func onPlaybackRateChanged(rate: Float)
    func onAudioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem)
}

open class QueuePlayer {

    open weak var delegate: QueuePlayerDelegate?

    public init() {
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        } else {
            try? AVAudioSession.sharedInstance().setCategoryiO9Compatible(.playback)
        }
    }

    private var player: AudioPlayer?

    open func play(request: AudioRequest) {
        player = AudioPlayer(request: request)
        player?.delegate = delegate
        player?.startPlaying()
    }

    public func pause() {
        player?.pause()
    }

    public func resume() {
        player?.resume()
    }

    public func stop() {
        player?.stop()
    }

    public func stepForward() {
        player?.stepForward()
    }

    public func stepBackward() {
        player?.stepBackgward()
    }
}
