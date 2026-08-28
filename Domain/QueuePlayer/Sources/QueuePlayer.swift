//
//  QueuePlayer.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/23/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation

public struct QueuePlayerActions: Sendable {
    // MARK: Lifecycle

    public init(
        playbackEnded: @Sendable @MainActor @escaping () -> Void,
        playbackRateChanged: @Sendable @MainActor @escaping (Float) -> Void,
        audioFrameChanged: @Sendable @MainActor @escaping (Int, Int, AVPlayerItem, TimeInterval?) -> Void,
        durationLoaded: @Sendable @MainActor @escaping (TimeInterval) -> Void,
        playbackTimeChanged: @Sendable @MainActor @escaping (TimeInterval) -> Void
    ) {
        self.playbackEnded = playbackEnded
        self.playbackRateChanged = playbackRateChanged
        self.audioFrameChanged = audioFrameChanged
        self.durationLoaded = durationLoaded
        self.playbackTimeChanged = playbackTimeChanged
    }

    // MARK: Internal

    let playbackEnded: @Sendable @MainActor () -> Void
    let playbackRateChanged: @Sendable @MainActor (Float) -> Void
    /// File index, frame index, the playing item, and its file's duration (`nil` while it loads).
    let audioFrameChanged: @Sendable @MainActor (Int, Int, AVPlayerItem, TimeInterval?) -> Void
    /// The playing file's duration finished loading; zero when it couldn't be read.
    let durationLoaded: @Sendable @MainActor (TimeInterval) -> Void

    /// Position within the file being played, on the media clock, while playing.
    let playbackTimeChanged: @Sendable @MainActor (TimeInterval) -> Void
}

@MainActor
public class QueuePlayer {
    // MARK: Lifecycle

    public convenience init() {
        self.init(sleep: { try? await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000)) })
    }

    init(sleep: @escaping VerseDelaySleep) {
        self.sleep = sleep
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
    }

    // MARK: Open

    open func play(request: AudioRequest, rate: Float) {
        player = AudioPlayer(request: request, rate: rate, sleep: sleep)
        player?.observesPlaybackTime = observesPlaybackTime
        player?.actions = newPlayerActions()
        player?.startPlaying()
    }

    // MARK: Public

    public var actions: QueuePlayerActions?

    /// Whether to report the playhead through `QueuePlayerActions.playbackTimeChanged`.
    public var observesPlaybackTime = false {
        didSet {
            guard observesPlaybackTime != oldValue else {
                return
            }
            player?.observesPlaybackTime = observesPlaybackTime
        }
    }

    public func pause() {
        player?.pause()
    }

    public func setRate(_ rate: Float) {
        player?.setRate(rate)
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

    // MARK: Private

    private let sleep: VerseDelaySleep

    private var player: AudioPlayer? {
        didSet {
            oldValue?.actions = nil
        }
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
                self?.actions?.audioFrameChanged($0, $1, $2, $3)
            },
            durationLoaded: { [weak self] in
                self?.actions?.durationLoaded($0)
            },
            playbackTimeChanged: { [weak self] in
                self?.actions?.playbackTimeChanged($0)
            }
        )
    }
}
