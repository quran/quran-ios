//
//  QueuePlayer.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/23/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation
import QueuePlayerObjc

public struct QueuePlayerActions: Sendable {
    let playbackEnded: @Sendable @MainActor () -> Void
    let playbackRateChanged: @Sendable @MainActor (Float) -> Void
    let audioFrameChanged: @Sendable @MainActor (Int, Int, AVPlayerItem) -> Void

    public init(
        playbackEnded: @Sendable @MainActor @escaping () -> Void,
        playbackRateChanged: @Sendable @MainActor @escaping (Float) -> Void,
        audioFrameChanged: @Sendable @MainActor @escaping (Int, Int, AVPlayerItem) -> Void
    ) {
        self.playbackEnded = playbackEnded
        self.playbackRateChanged = playbackRateChanged
        self.audioFrameChanged = audioFrameChanged
    }
}

@MainActor
public class QueuePlayer {
    public var actions: QueuePlayerActions?

    public init() {
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        } else {
            try? AVAudioSession.sharedInstance().setCategoryiO9Compatible(.playback)
        }
    }

    private var player: AudioPlayer? {
        didSet {
            oldValue?.actions = nil
        }
    }

    open func play(request: AudioRequest) {
        player = AudioPlayer(request: request)
        player?.actions = newPlayerActions()
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

    private func playbackEnded() {
        player = nil
        actions?.playbackEnded()
    }

    private func newPlayerActions() -> QueuePlayerActions {
        QueuePlayerActions(
            playbackEnded: { [weak self] in
                self?.playbackEnded()
            },
            playbackRateChanged: { [weak self] in
                self?.actions?.playbackRateChanged($0)
            },
            audioFrameChanged: { [weak self] in
                self?.actions?.audioFrameChanged($0, $1, $2)
            }
        )
    }
}
