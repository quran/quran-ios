//
//  DefaultAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import BatchDownloader
import PromiseKit
import QueuePlayer

protocol DefaultAudioPlayerInteractor: AudioPlayerInteractor, AudioPlayerDelegate {

    var downloader: AudioFilesDownloader { get }

    var player: AudioPlayer { get }

    var lastAyahFinder: LastAyahFinder { get }

    var downloadCancelled: Bool { get set }

    func prePlayOperation(qari: Qari, range: VerseRange, completion: @escaping () -> Void)
}

extension DefaultAudioPlayerInteractor {

    fileprivate typealias PlaybackInfo = (qari: Qari, range: VerseRange)

    func prePlayOperation(qari: Qari, range: VerseRange, completion: @escaping () -> Void) {
        completion()
    }

    func isAudioDownloading() -> Promise<Bool> {
        return downloader.getCurrentDownloadResponse()
            .do { self.gotDownloadResponse($0, playbackInfo: nil) }
            .then { $0 != nil }
    }

    func playAudioForQari(_ qari: Qari, range: VerseRange) {
        if downloader.needsToDownloadFiles(qari: qari, range: range) {
            Analytics.shared.downloadingJuz(startAyah: range.lowerBound, qari: qari)
            downloadCancelled = false
            delegate?.willStartDownloading()
            downloader
                .download(qari: qari, range: range)
                .then(on: .main) { response -> Void in
                    guard let response = response else {
                        return
                    }

                    if self.downloadCancelled {
                        response.cancel()
                    } else {
                        self.gotDownloadResponse(response, playbackInfo: (qari: qari, range: range))
                    }
                }.suppress()
        } else {
            startPlaying((qari: qari, range: range))
        }
    }

    func getAyahRange(starting startAyah: AyahNumber, page: QuranPage) -> VerseRange {
        let endAyah = lastAyahFinder.findLastAyah(startAyah: startAyah, page: page.pageNumber)
        return VerseRange(lowerBound: startAyah, upperBound: endAyah)
    }

    func cancelDownload() {
        downloadCancelled = true
        downloader.cancel()
        delegate?.onPlaybackOrDownloadingCompleted()
    }

    func pauseAudio() {
        player.pause()
    }

    func resumeAudio() {
        player.resume()
    }

    func stopAudio() {
        player.stop()
    }

    func goForward() {
        player.goForward()
    }

    func goBackward() {
        player.goBackward()
    }

    func setVerseRuns(_ runs: Runs) {
        player.setVerseRuns(runs)
    }

    func setListRuns(_ runs: Runs) {
        player.setListRuns(runs)
    }

    // MARK: - AudioPlayerDelegate

    func onPlaybackPaused() {
        delegate?.onPlaybackPaused()
    }

    func onPlaybackResumed() {
        delegate?.onPlaybackResumed()
    }

    func onPlaybackEnded() {
        delegate?.onPlaybackOrDownloadingCompleted()
    }

    func playingAyah(_ ayah: AyahNumber) {
        delegate?.highlight(ayah)
    }

    fileprivate func gotDownloadResponse(_ response: DownloadBatchResponse, playbackInfo: PlaybackInfo?) {

        delegate?.didStartDownloadingAudioFiles(progress: response.progress)
        response.promise
            .then { [weak self] () -> Void in
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

    fileprivate func startPlaying(_ playbackInfo: PlaybackInfo) {
        Analytics.shared.playing(startAyah: playbackInfo.range.lowerBound, qari: playbackInfo.qari)
        prePlayOperation(qari: playbackInfo.qari, range: playbackInfo.range) { [weak self] in
            self?.player.play(qari: playbackInfo.qari, range: playbackInfo.range)
            self?.delegate?.onPlayingStarted()
        }
    }
}
