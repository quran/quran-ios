//
//  QuranAudioPlayer.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AudioTimingPersistence
import AVFoundation
import QueuePlayer
import QuranKit
import Reciter
import Utilities
import VLogging

public struct QuranAudioPlayerActions: Sendable {
    let playbackEnded: @Sendable @MainActor () -> Void
    let playbackPaused: @Sendable @MainActor () -> Void
    let playbackResumed: @Sendable @MainActor () -> Void
    let playing: @Sendable @MainActor (AyahNumber) -> Void

    public init(playbackEnded: @Sendable @MainActor @escaping () -> Void,
                playbackPaused: @Sendable @MainActor @escaping () -> Void,
                playbackResumed: @Sendable @MainActor @escaping () -> Void,
                playing: @Sendable @MainActor @escaping (AyahNumber) -> Void)
    {
        self.playbackEnded = playbackEnded
        self.playbackPaused = playbackPaused
        self.playbackResumed = playbackResumed
        self.playing = playing
    }
}

@MainActor
public class QuranAudioPlayer {
    public var actions: QuranAudioPlayerActions?
    public func setActions(_ actions: QuranAudioPlayerActions) {
        self.actions = actions
    }

    private let player: QueuingPlayer
    private let unzipper: AudioUnzipper
    private let nowPlaying = NowPlayingUpdater(center: .default())

    private let gappedAudioRequestBuilder: QuranAudioRequestBuilder = GappedAudioRequestBuilder()
    private let gaplessAudioRequestBuilder: QuranAudioRequestBuilder = GaplessAudioRequestBuilder()
    private var audioRequest: QuranAudioRequest?

    init(player: QueuingPlayer) {
        self.player = player
        unzipper = AudioUnzipper()
    }

    public convenience init() {
        self.init(player: QueuePlayer())
    }

    // MARK: - Playback Controls

    public func pauseAudio() {
        player.pause()
    }

    public func resumeAudio() {
        player.resume()
    }

    public func stopAudio() {
        player.stop()
    }

    public func stepForward() {
        player.stepForward()
    }

    public func stepBackward() {
        player.stepBackward()
    }

    // MARK: - AudioPlayerActions

    private func playbackEnded() {
        nowPlaying.clear()
        actions?.playbackEnded()
        // not interested to get more notifications
        player.actions = nil
        audioRequest = nil
    }

    private func playbackRateChanged(rate: Float) {
        nowPlaying.update(rate: rate)
        if rate > 0.1 {
            actions?.playbackResumed()
        } else {
            actions?.playbackPaused()
        }
    }

    private func audioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem) {
        guard let audioRequest else {
            return
        }

        let info = audioRequest.getPlayerInfo(for: fileIndex)
        nowPlaying.update(info: info)
        nowPlaying.update(playingIndex: fileIndex)
        nowPlaying.update(duration: playerItem.asset.duration.seconds)
        nowPlaying.update(elapsedTime: playerItem.currentTime().seconds)

        let ayah = audioRequest.getAyahNumberFrom(fileIndex: fileIndex, frameIndex: frameIndex)
        actions?.playing(ayah)
    }

    // MARK: - Play

    public func play(reciter: Reciter,
                     from start: AyahNumber,
                     to end: AyahNumber,
                     verseRuns: Runs,
                     listRuns: Runs) async throws
    {
        let details: [String: Any] = [
            "startAyah": start,
            "to": end,
            "reciter": reciter,
            "verseRuns": verseRuns,
            "listRuns": listRuns,
        ]
        logger.notice("Playing \(details.map { "\($0): \($1)" }.joined(separator: ", "))")
        try await unzipper.unzip(reciter: reciter)

        let builder = getAudioRequestBuilder(for: reciter)
        let audioRequest = try await builder.buildRequest(with: reciter, from: start, to: end, frameRuns: verseRuns, requestRuns: listRuns)
        let request = audioRequest.getRequest()
        willPlay(request)
        self.audioRequest = audioRequest
        player.actions = newPlayerActions()
        player.play(request: request)
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
                self?.playbackEnded()
            },
            playbackRateChanged: { [weak self] rate in
                self?.playbackRateChanged(rate: rate)
            },
            audioFrameChanged: { [weak self] in
                self?.audioFrameChanged(fileIndex: $0, frameIndex: $1, playerItem: $2)
            }
        )
    }
}
