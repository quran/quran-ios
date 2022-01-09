//
//  QuranAudioPlayer.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AVFoundation
import BatchDownloader
import PromiseKit
import QueuePlayer
import QuranKit
import VLogging

public protocol QuranAudioPlayerDelegate: AnyObject {
    func willStartDownloading()
    func didStartDownloadingAudioFiles(progress: QProgress)

    func onPlayingStarted()

    func onPlaybackPaused()

    func onPlaybackResumed()

    func onPlaying(ayah: AyahNumber)

    func onFailedDownloadingWithError(_ error: Error)
    func onFailedPlaybackWithError(_ error: Error)

    func onPlaybackOrDownloadingCompleted()
}

public protocol QuranAudioPlayer: AnyObject {
    var delegate: QuranAudioPlayerDelegate? { get set }
    var verseRuns: Runs { get set }
    var listRuns: Runs { get set }

    func isAudioDownloading() -> Guarantee<Bool>
    func cancelDownload()
    func playAudioForReciter(_ reciter: Reciter, from start: AyahNumber, to end: AyahNumber)
    func pauseAudio()
    func resumeAudio()
    func stopAudio()
    func stepForward()
    func stepBackward()
}

class DefaultQuranAudioPlayer: QuranAudioPlayer, QueuePlayerDelegate {
    weak var delegate: QuranAudioPlayerDelegate?

    private let downloader: AudioFilesDownloader
    private let player: QueuePlayer
    private let unzipper: AudioUnzipper
    private let nowPlaying: NowPlayingUpdater

    private let gappedAudioRequestBuilder: QuranAudioRequestBuilder
    private let gaplessAudioRequestBuilder: QuranAudioRequestBuilder
    private var audioRequest: QuranAudioRequest?

    private var downloadCancelled: Bool = false

    var verseRuns: Runs = .one
    var listRuns: Runs = .one

    init(downloader: AudioFilesDownloader,
         player: QueuePlayer,
         unzipper: AudioUnzipper,
         gappedAudioRequestBuilder: QuranAudioRequestBuilder,
         gaplessAudioRequestBuilder: QuranAudioRequestBuilder,
         nowPlaying: NowPlayingUpdater)
    {
        self.downloader = downloader
        self.player = player
        self.unzipper = unzipper
        self.gappedAudioRequestBuilder = gappedAudioRequestBuilder
        self.gaplessAudioRequestBuilder = gaplessAudioRequestBuilder
        self.nowPlaying = nowPlaying
    }

    private typealias PlaybackInfo = (reciter: Reciter, start: AyahNumber, end: AyahNumber)

    // MARK: - Playback Controls

    func pauseAudio() {
        player.pause()
    }

    func resumeAudio() {
        player.resume()
    }

    func stopAudio() {
        player.stop()
    }

    func stepForward() {
        player.stepForward()
    }

    func stepBackward() {
        player.stepBackward()
    }

    // MARK: - AudioPlayerDelegate

    func onPlaybackEnded() {
        nowPlaying.clear()
        delegate?.onPlaybackOrDownloadingCompleted()
        // not interested to get more notifications
        player.delegate = nil
        audioRequest = nil
    }

    func onPlaybackRateChanged(rate: Float) {
        nowPlaying.update(rate: rate)
        if rate > 0.1 {
            delegate?.onPlaybackResumed()
        } else {
            delegate?.onPlaybackPaused()
        }
    }

    func onAudioFrameChanged(fileIndex: Int, frameIndex: Int, playerItem: AVPlayerItem) {
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

    // MARK: - Download

    // will call willStartDownloadingAudioFiles if there is downloads
    func isAudioDownloading() -> Guarantee<Bool> {
        downloader.getCurrentDownloadResponse()
            .get { response in
                if let response = response {
                    self.gotDownloadResponse(response, playbackInfo: nil)
                }
            }
            .map { $0 != nil }
    }

    func cancelDownload() {
        downloadCancelled = true
        downloader.cancel()
        delegate?.onPlaybackOrDownloadingCompleted()
    }

    private func gotDownloadResponse(_ response: DownloadBatchResponse, playbackInfo: PlaybackInfo?) {
        delegate?.didStartDownloadingAudioFiles(progress: response.progress)
        response.promise
            .done { [weak self] () -> Void in
                if let playbackInfo = playbackInfo {
                    self?.startPlaying(playbackInfo)
                } else {
                    self?.delegate?.onPlaybackOrDownloadingCompleted()
                }
            }
            .catch { [weak self] error in
                self?.delegate?.onPlaybackOrDownloadingCompleted()
                self?.delegate?.onFailedDownloadingWithError(error)
            }
    }

    // MARK: - Play

    func playAudioForReciter(_ reciter: Reciter, from start: AyahNumber, to end: AyahNumber) {
        let playbackInfo = (reciter: reciter, start: start, end: end)
        if downloader.needsToDownloadFiles(reciter: reciter, from: start, to: end) {
            logger.notice("Downloading Juz starting ayah: \(start) to \(end). Reciter: \(reciter)")
            downloadCancelled = false
            delegate?.willStartDownloading()
            downloader
                .download(reciter: reciter, from: start, to: end)
                .done(on: .main) { response -> Void in
                    guard let response = response else {
                        return
                    }

                    if self.downloadCancelled {
                        response.cancel()
                    } else {
                        self.gotDownloadResponse(response, playbackInfo: playbackInfo)
                    }
                }
                .catch { error in
                    self.delegate?.onFailedPlaybackWithError(error)
                }
        } else {
            startPlaying(playbackInfo)
        }
    }

    private func startPlaying(_ playbackInfo: PlaybackInfo) {
        let details: [String: Any] = [
            "startAyah": playbackInfo.start,
            "to": playbackInfo.end,
            "reciter": playbackInfo.reciter,
            "verseRuns": verseRuns,
            "listRuns": listRuns,
        ]
        logger.notice("Playing \(details.map { "\($0): \($1)" }.joined(separator: ", "))")
        unzipper.unzip(reciter: playbackInfo.reciter).done(on: .main) {
            self.play(reciter: playbackInfo.reciter, from: playbackInfo.start, to: playbackInfo.end)
            self.delegate?.onPlayingStarted()
        }
    }

    private func play(reciter: Reciter, from start: AyahNumber, to end: AyahNumber) {
        let builder = getAudioRequestBuilder(for: reciter)
        builder.buildRequest(with: reciter, from: start, to: end, frameRuns: verseRuns, requestRuns: listRuns)
            .done(on: .main) { audioRequest in
                let request = audioRequest.getRequest()
                self.willPlay(request)
                self.audioRequest = audioRequest
                self.player.delegate = self
                self.player.play(request: request)
            }
            .catch { error in
                self.delegate?.onFailedPlaybackWithError(error)
            }
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
