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
        playbackEnded: @Sendable @MainActor @escaping (PlaybackEndReason) -> Void,
        playbackRateChanged: @Sendable @MainActor @escaping (Float) -> Void,
        audioFrameChanged: @Sendable @MainActor @escaping (Int, Int, AVPlayerItem, TimeInterval?) -> Void,
        durationLoaded: @Sendable @MainActor @escaping (TimeInterval) -> Void,
        playbackFailed: @Sendable @MainActor @escaping (Error) -> Void = { _ in }
    ) {
        self.playbackEnded = playbackEnded
        self.playbackRateChanged = playbackRateChanged
        self.audioFrameChanged = audioFrameChanged
        self.durationLoaded = durationLoaded
        self.playbackFailed = playbackFailed
    }

    // MARK: Internal

    let playbackEnded: @Sendable @MainActor (PlaybackEndReason) -> Void
    let playbackFailed: @Sendable @MainActor (Error) -> Void
    let playbackRateChanged: @Sendable @MainActor (Float) -> Void
    /// File index, frame index, the playing item, and its file's duration (`nil` while it loads).
    let audioFrameChanged: @Sendable @MainActor (Int, Int, AVPlayerItem, TimeInterval?) -> Void
    /// The playing file's duration finished loading successfully.
    let durationLoaded: @Sendable @MainActor (TimeInterval) -> Void
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
        player?.actions = newPlayerActions()
        player?.startPlaying()
    }

    // MARK: Public

    public var actions: QueuePlayerActions?

    /// Waits for the current request's first item to be ready, including failures and cancellation.
    public func waitUntilReady() async throws {
        guard let player else { throw PlaybackError.unavailable }
        try await player.waitUntilReady()
        guard self.player === player else { throw CancellationError() }
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

    private func playbackEnded(_ reason: PlaybackEndReason) {
        player = nil
        actions?.playbackEnded(reason)
    }

    private func playbackFailed(_ error: Error) {
        player = nil
        actions?.playbackFailed(error)
    }

    private func newPlayerActions() -> QueuePlayerActions {
        QueuePlayerActions(
            playbackEnded: { [weak self] in
                self?.playbackEnded($0)
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
            playbackFailed: { [weak self] in
                self?.playbackFailed($0)
            }
        )
    }
}
