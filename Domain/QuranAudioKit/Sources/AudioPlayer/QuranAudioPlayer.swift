//
//  QuranAudioPlayer.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation
import QueuePlayer
import QuranAudio
import QuranKit
import ReciterService
import VLogging

public struct QuranAudioPlayerActions: Sendable {
    // MARK: Lifecycle

    public init(
        playbackEnded: @Sendable @MainActor @escaping (PlaybackEndReason) -> Void,
        playbackPaused: @Sendable @MainActor @escaping () -> Void,
        playbackResumed: @Sendable @MainActor @escaping () -> Void,
        playing: @Sendable @MainActor @escaping (AyahNumber) -> Void,
        playbackFailed: @Sendable @MainActor @escaping (Error) -> Void = { _ in }
    ) {
        self.playbackEnded = playbackEnded
        self.playbackPaused = playbackPaused
        self.playbackResumed = playbackResumed
        self.playing = playing
        self.playbackFailed = playbackFailed
    }

    // MARK: Internal

    let playbackEnded: @Sendable @MainActor (PlaybackEndReason) -> Void
    let playbackFailed: @Sendable @MainActor (Error) -> Void
    let playbackPaused: @Sendable @MainActor () -> Void
    let playbackResumed: @Sendable @MainActor () -> Void
    let playing: @Sendable @MainActor (AyahNumber) -> Void
}

@MainActor
public class QuranAudioPlayer {
    // MARK: Lifecycle

    init(player: QueuingPlayer) {
        self.player = player
        unzipper = AudioUnzipper()
    }

    public convenience init() {
        self.init(player: QueuePlayer())
    }

    // MARK: Public

    public var actions: QuranAudioPlayerActions?

    public func setActions(_ actions: QuranAudioPlayerActions) {
        self.actions = actions
    }

    // MARK: - Playback Controls

    public func pauseAudio() {
        player.pause()
    }

    public func resumeAudio() {
        player.resume()
    }

    public func stopAudio() {
        generation &+= 1
        player.stop()
    }

    public func stepForward() {
        player.stepForward()
    }

    public func stepBackward() {
        player.stepBackward()
    }

    public func setRate(_ rate: Float) {
        player.setRate(rate)
    }

    // MARK: - Play

    public func play(
        reciter: Reciter,
        rate: Float,
        from start: AyahNumber,
        to end: AyahNumber,
        verseRuns: Runs,
        listRuns: Runs,
        verseDelay: VerseDelay = .none,
        repetitionDelay: RepetitionDelay = .none,
        streaming: Bool = false
    ) async throws {
        generation &+= 1
        let requestGeneration = generation
        let details: [String: Any] = [
            "startAyah": start,
            "to": end,
            "reciter": reciter,
            "verseRuns": verseRuns,
            "listRuns": listRuns,
            "verseDelay": verseDelay,
            "repetitionDelay": repetitionDelay,
            "streaming": streaming,
        ]
        logger.notice("Playing \(details.map { "\($0): \($1)" }.joined(separator: ", "))")
        try await unzipper.unzip(reciter: reciter)

        let builder = getAudioRequestBuilder(for: reciter)
        var audioRequest = try await builder.buildRequest(with: reciter, from: start, to: end, frameRuns: verseRuns, requestRuns: listRuns, streaming: streaming)
        audioRequest = audioRequest.withVerseDelay(verseDelay)
        audioRequest = audioRequest.withRepetitionDelay(repetitionDelay)
        let request = audioRequest.getRequest()
        try Task.checkCancellation()
        guard requestGeneration == generation else { throw CancellationError() }
        willPlay(request)
        self.audioRequest = audioRequest
        player.actions = newPlayerActions()
        player.play(request: request, rate: rate)
        do {
            try await player.waitUntilReady()
        } catch {
            if requestGeneration == generation {
                player.stop()
            }
            throw error
        }
    }

    // MARK: Private

    private let player: QueuingPlayer
    private let unzipper: AudioUnzipper
    private let nowPlaying = NowPlayingUpdater(center: .default())

    private let gappedAudioRequestBuilder: QuranAudioRequestBuilder = GappedAudioRequestBuilder()
    private let gaplessAudioRequestBuilder: QuranAudioRequestBuilder = GaplessAudioRequestBuilder()
    private var audioRequest: QuranAudioRequest?
    private var generation: UInt = 0

    // MARK: - AudioPlayerActions

    private func playbackEnded(_ reason: PlaybackEndReason) {
        nowPlaying.clear()
        actions?.playbackEnded(reason)
        // not interested to get more notifications
        player.actions = nil
        audioRequest = nil
    }

    private func playbackFailed(_ error: Error) {
        nowPlaying.clear()
        player.actions = nil
        audioRequest = nil
        actions?.playbackFailed(error)
    }

    private func playbackRateChanged(rate: Float) {
        nowPlaying.update(rate: rate)
        if rate > 0.1 {
            actions?.playbackResumed()
        } else {
            actions?.playbackPaused()
        }
    }

    private func audioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem, duration: TimeInterval?) {
        guard let audioRequest else {
            return
        }

        let info = audioRequest.getPlayerInfo(for: fileIndex)
        nowPlaying.update(info: info)
        nowPlaying.update(playingIndex: fileIndex)
        // Zero until `durationLoaded(_:)`, so the previous file's duration never shows.
        nowPlaying.update(duration: duration ?? 0)
        nowPlaying.update(elapsedTime: playerItem.currentTime().seconds)

        let ayah = audioRequest.getAyahNumberFrom(fileIndex: fileIndex, frameIndex: frameIndex)
        actions?.playing(ayah)
    }

    private func durationLoaded(_ duration: TimeInterval) {
        guard audioRequest != nil else {
            return
        }
        nowPlaying.update(duration: duration)
    }

    private func willPlay(_ request: AudioRequest) {
        nowPlaying.clear()
        nowPlaying.update(count: request.files.count)
    }

    private func getAudioRequestBuilder(for reciter: Reciter) -> QuranAudioRequestBuilder {
        switch reciter.audioType {
        case .gapless: return gaplessAudioRequestBuilder
        case .gapped: return gappedAudioRequestBuilder
        }
    }

    private func newPlayerActions() -> QueuePlayerActions {
        QueuePlayerActions(
            playbackEnded: { [weak self] in
                self?.playbackEnded($0)
            },
            playbackRateChanged: { [weak self] rate in
                self?.playbackRateChanged(rate: rate)
            },
            audioFrameChanged: { [weak self] in
                self?.audioFrameChanged(fileIndex: $0, frameIndex: $1, playerItem: $2, duration: $3)
            },
            durationLoaded: { [weak self] in
                self?.durationLoaded($0)
            },
            playbackFailed: { [weak self] in
                self?.playbackFailed($0)
            }
        )
    }
}
