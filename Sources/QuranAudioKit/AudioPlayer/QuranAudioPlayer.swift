//
//  QuranAudioPlayer.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AsyncExtensions
import AVFoundation
import QueuePlayer
import QuranKit
import Utilities
import VLogging

public protocol QuranAudioPlayerDelegate: AnyObject {
    func onPlaybackPaused()
    func onPlaybackResumed()
    func onPlaying(ayah: AyahNumber)
    func onPlaybackEnded()
}

public class QuranAudioPlayer: QueuePlayerDelegate {
    public weak var delegate: QuranAudioPlayerDelegate?

    private let player: QueuingPlayer
    private let unzipper: AudioUnzipper
    private let nowPlaying: NowPlayingUpdater

    private let gappedAudioRequestBuilder: QuranAudioRequestBuilder
    private let gaplessAudioRequestBuilder: QuranAudioRequestBuilder
    private var audioRequest: QuranAudioRequest?

    init(player: QueuingPlayer) {
        let timingRetriever = SQLiteReciterTimingRetriever(persistenceFactory: DefaultAyahTimingPersistenceFactory())
        let gaplessBuilder = GaplessAudioRequestBuilder(timingRetriever: timingRetriever)
        let gappedBuilder = GappedAudioRequestBuilder()
        self.player = player
        unzipper = AudioUnzipper()
        gappedAudioRequestBuilder = gappedBuilder
        gaplessAudioRequestBuilder = gaplessBuilder
        nowPlaying = NowPlayingUpdater(center: .default())
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

    // MARK: - AudioPlayerDelegate

    // TODO: remove public
    public func onPlaybackEnded() {
        nowPlaying.clear()
        delegate?.onPlaybackEnded()
        // not interested to get more notifications
        player.delegate = nil
        audioRequest = nil
    }

    // TODO: remove public
    public func onPlaybackRateChanged(rate: Float) {
        nowPlaying.update(rate: rate)
        if rate > 0.1 {
            delegate?.onPlaybackResumed()
        } else {
            delegate?.onPlaybackPaused()
        }
    }

    // TODO: remove public
    public func onAudioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem) {
        guard let audioRequest = audioRequest else {
            return
        }

        let info = audioRequest.getPlayerInfo(for: fileIndex)
        nowPlaying.update(info: info)
        nowPlaying.update(playingIndex: fileIndex)
        nowPlaying.update(duration: playerItem.asset.duration.seconds)
        nowPlaying.update(elapsedTime: playerItem.currentTime().seconds)

        let ayah = audioRequest.getAyahNumberFrom(fileIndex: fileIndex, frameIndex: frameIndex)
        delegate?.onPlaying(ayah: ayah)
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
        player.delegate = self
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
}
