//
//  QuranAudioPlayer.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/28/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import BatchDownloader
import PromiseKit
import QueuePlayer

protocol QuranAudioPlayerDelegate: class {
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

class QuranAudioPlayer: QueuePlayerDelegate {

    weak var delegate: QuranAudioPlayerDelegate?

    private let downloader: AudioFilesDownloader
    private let player: QueuePlayer
    private let lastAyahFinder: LastAyahFinder
    private let unzipper: AudioUnzipper
    private let nowPlaying: NowPlayingUpdater

    private let gappedAudioRequestBuilder: QuranAudioRequestBuilder
    private let gaplessAudioRequestBuilder: QuranAudioRequestBuilder
    private var audioRequest: QuranAudioRequest?

    private var downloadCancelled: Bool = false

    var verseRuns: Runs = .one
    var listRuns: Runs = .one

    init(downloader: AudioFilesDownloader,
         lastAyahFinder: LastAyahFinder,
         player: QueuePlayer,
         unzipper: AudioUnzipper,
         gappedAudioRequestBuilder: QuranAudioRequestBuilder,
         gaplessAudioRequestBuilder: QuranAudioRequestBuilder,
         nowPlaying: NowPlayingUpdater) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
        self.player = player
        self.unzipper = unzipper
        self.gappedAudioRequestBuilder = gappedAudioRequestBuilder
        self.gaplessAudioRequestBuilder = gaplessAudioRequestBuilder
        self.nowPlaying = nowPlaying
    }

    private typealias PlaybackInfo = (qari: Qari, range: VerseRange)

    func getAyahRange(starting startAyah: AyahNumber, page: QuranPage) -> VerseRange {
        let endAyah = lastAyahFinder.findLastAyah(startAyah: startAyah, page: page.pageNumber)
        //        let endAyah = AyahNumber(sura: 112, ayah: 4)
        return VerseRange(lowerBound: startAyah, upperBound: endAyah)
    }

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
        return downloader.getCurrentDownloadResponse()
            .get { response in
                if let response = response {
                    self.gotDownloadResponse(response, playbackInfo: nil)
                }
            }.map { $0 != nil }
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
            }.catch { [weak self] error in
                self?.delegate?.onPlaybackOrDownloadingCompleted()
                self?.delegate?.onFailedDownloadingWithError(error)
            }
    }

    // MARK: - Play

    func playAudioForQari(_ qari: Qari, range: VerseRange) {
        if downloader.needsToDownloadFiles(qari: qari, range: range) {
            Analytics.shared.downloadingJuz(startAyah: range.lowerBound, qari: qari)
            downloadCancelled = false
            delegate?.willStartDownloading()
            downloader
                .download(qari: qari, range: range)
                .done(on: .main) { response -> Void in
                    guard let response = response else {
                        return
                    }

                    if self.downloadCancelled {
                        response.cancel()
                    } else {
                        self.gotDownloadResponse(response, playbackInfo: (qari: qari, range: range))
                    }
                }.catch { error in
                    self.delegate?.onFailedPlaybackWithError(error)
                }
        } else {
            startPlaying((qari: qari, range: range))
        }
    }

    private func startPlaying(_ playbackInfo: PlaybackInfo) {
        Analytics.shared.playing(
            startAyah: playbackInfo.range.lowerBound,
            to: playbackInfo.range.upperBound,
            qari: playbackInfo.qari,
            verseRuns: verseRuns,
            listRuns: listRuns
        )
        unzipper.unzip(qari: playbackInfo.qari).done(on: .main) {
            self.play(qari: playbackInfo.qari, range: playbackInfo.range)
            self.delegate?.onPlayingStarted()
        }
    }

    private func play(qari: Qari, range: VerseRange) {
        let builder = getAudioRequestBuilder(for: qari)
        builder.buildRequest(with: qari, verseRange: range, frameRuns: verseRuns, requestRuns: listRuns)
            .done(on: .main) { audioRequest in
                let request = audioRequest.getRequest()
                self.willPlay(request)
                self.audioRequest = audioRequest
                self.player.delegate = self
                self.player.play(request: request)
            }.catch { error in
                self.delegate?.onFailedPlaybackWithError(error)
            }
    }

    private func willPlay(_ request: AudioRequest) {
        nowPlaying.clear()
        nowPlaying.update(count: request.files.count)
    }

    private func getAudioRequestBuilder(for qari: Qari) -> QuranAudioRequestBuilder {
        switch qari.audioType {
        case .gapless: return gaplessAudioRequestBuilder
        case .gapped: return gappedAudioRequestBuilder
        }
    }
}
