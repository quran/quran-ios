//
//  QueuePlayer.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/23/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation
import QueuePlayerObjc

public protocol QueuePlayerDelegate: AnyObject {
    func onPlaybackEnded()
    func onPlaybackRateChanged(rate: Float)
    func onAudioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem)
}

open class QueuePlayer: QueuePlayerDelegate {
    open weak var delegate: QueuePlayerDelegate?

    public init() {
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        } else {
            try? AVAudioSession.sharedInstance().setCategoryiO9Compatible(.playback)
        }
    }

    private var player: AudioPlayer? {
        didSet {
            oldValue?.delegate = nil
        }
    }

    open func play(request: AudioRequest) {
        player = AudioPlayer(request: request)
        player?.delegate = self
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
        player = nil
    }

    public func stepForward() {
        player?.stepForward()
    }

    public func stepBackward() {
        player?.stepBackgward()
    }

    // MARK: - QueuePlayerDelegate

    public func onPlaybackEnded() {
        player = nil
        delegate?.onPlaybackEnded()
    }

    public func onPlaybackRateChanged(rate: Float) {
        delegate?.onPlaybackRateChanged(rate: rate)
    }

    public func onAudioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem) {
        delegate?.onAudioFrameChanged(fileIndex: fileIndex, frameIndex: frameIndex, playerItem: playerItem)
    }
}
