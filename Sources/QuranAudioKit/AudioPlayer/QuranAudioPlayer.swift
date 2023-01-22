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

public class QuranAudioPlayer: QueuePlayerDelegate {
    public weak var delegate: QuranAudioPlayerDelegate?

    private let downloader: AudioFilesDownloader
    private let player: QueuingPlayer
    private let unzipper: AudioUnzipper
    private let nowPlaying: NowPlayingUpdater

    private let gappedAudioRequestBuilder: QuranAudioRequestBuilder
    private let gaplessAudioRequestBuilder: QuranAudioRequestBuilder
    private var audioRequest: QuranAudioRequest?

    private var downloadCancelled: Bool = false

    public var verseRuns: Runs = .one
    public var listRuns: Runs = .one

    init(baseURL: URL, downloadManager: DownloadManager, player: QueuingPlayer, fileSystem: FileSystem) {
        let timingRetriever = SQLiteReciterTimingRetriever(persistenceFactory: DefaultAyahTimingPersistenceFactory())
        let gaplessBuilder = GaplessAudioRequestBuilder(timingRetriever: timingRetriever)
        let gappedBuilder = GappedAudioRequestBuilder()
        let fileListFactory = DefaultReciterAudioFileListRetrievalFactory(quran: Quran.madani, baseURL: baseURL)
        let versesDownloader = AyahsAudioDownloader(downloader: downloadManager, fileListFactory: fileListFactory)
        downloader = AudioFilesDownloader(fileListFactory: fileListFactory,
                                          downloader: downloadManager,
                                          ayahDownloader: versesDownloader,
                                          fileSystem: fileSystem)
        self.player = player
        unzipper = AudioUnzipper()
        gappedAudioRequestBuilder = gappedBuilder
        gaplessAudioRequestBuilder = gaplessBuilder
        nowPlaying = NowPlayingUpdater(center: .default())
    }

    public convenience init(baseURL: URL, downloadManager: DownloadManager) {
        self.init(baseURL: baseURL, downloadManager: downloadManager, player: QueuePlayer(), fileSystem: DefaultFileSystem())
    }

    private typealias PlaybackInfo = (reciter: Reciter, start: AyahNumber, end: AyahNumber)

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
        delegate?.onPlaybackOrDownloadingCompleted()
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

    // MARK: - Download

    // will call willStartDownloadingAudioFiles if there is downloads
    public func isAudioDownloading() -> Guarantee<Bool> {
        downloader.getCurrentDownloadResponse()
            .get { response in
                if let response = response {
                    self.gotDownloadResponse(response, playbackInfo: nil)
                }
            }
            .map { $0 != nil }
    }

    public func cancelDownload() {
        downloadCancelled = true
        downloader.cancel()
        delegate?.onPlaybackOrDownloadingCompleted()
    }

    private func gotDownloadResponse(_ response: DownloadBatchResponse, playbackInfo: PlaybackInfo?) {
        delegate?.didStartDownloadingAudioFiles(progress: response.progress)
        response.promise
            .done { [weak self] () in
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

    public func playAudioForReciter(_ reciter: Reciter, from start: AyahNumber, to end: AyahNumber) {
        let playbackInfo = (reciter: reciter, start: start, end: end)
        if downloader.needsToDownloadFiles(reciter: reciter, from: start, to: end) {
            logger.notice("Downloading Juz starting ayah: \(start) to \(end). Reciter: \(reciter)")
            downloadCancelled = false
            delegate?.willStartDownloading()
            downloader
                .download(reciter: reciter, from: start, to: end)
                .done(on: .main) { response in
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
        }
    }

    private func play(reciter: Reciter, from start: AyahNumber, to end: AyahNumber) {
        let builder = getAudioRequestBuilder(for: reciter)
        builder.buildRequest(with: reciter, from: start, to: end, frameRuns: verseRuns, requestRuns: listRuns)
            .done(on: .main) { audioRequest in
                let request = audioRequest.getRequest()
                self.delegate?.onPlayingStarted()
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
