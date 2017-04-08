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

import Foundation

protocol DefaultAudioPlayerInteractor: AudioPlayerInteractor, AudioPlayerDelegate {

    var downloader: AudioFilesDownloader { get }

    var player: AudioPlayer { get }

    var lastAyahFinder: LastAyahFinder { get }

    var downloadCancelled: Bool { get set }

    func prePlayOperation(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, completion: @escaping () -> Void)
}

extension DefaultAudioPlayerInteractor {

    fileprivate typealias PlaybackInfo = (qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber)

    func prePlayOperation(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, completion: @escaping () -> Void) {
        completion()
    }

    func checkIfDownloading(_ completion: @escaping (_ downloading: Bool) -> Void) {
        downloader.getCurrentDownloadResponse().then { response -> Void in
            guard let response = response else {
                completion(false)
                return
            }
            self.gotDownloadResponse(response, playbackInfo: nil)
            completion(true)
            }.cauterize(tag: "checkIfDownloading")
    }

    func playAudioForQari(_ qari: Qari, atPage page: QuranPage) {

        let startAyah = Quran.startAyahForPage(page.pageNumber)
        let endAyah = lastAyahFinder.findLastAyah(startAyah: startAyah, page: page.pageNumber)

        if downloader.needsToDownloadFiles(qari: qari, startAyah: startAyah, endAyah: endAyah) {
            downloadCancelled = false
            Queue.background.async {
                self.delegate?.willStartDownloading()
                if let response = self.downloader.download(qari: qari, startAyah: startAyah, endAyah: endAyah) {
                    if self.downloadCancelled {
                        response.cancel()
                    } else {
                        self.gotDownloadResponse(response, playbackInfo: (qari: qari, startAyah: startAyah, endAyah: endAyah))
                    }
                }
            }
        } else {
            startPlaying(qari: qari, startAyah: startAyah, endAyah: endAyah)
        }
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

    fileprivate func gotDownloadResponse(_ response: Response, playbackInfo: PlaybackInfo?) {

        delegate?.didStartDownloadingAudioFiles(progress: response.progress)
        response.onCompletion = { [weak self] result in
            switch result {
            case .success:
                if let playbackInfo = playbackInfo {
                    self?.startPlaying(playbackInfo)
                } else {
                    self?.delegate?.onPlaybackOrDownloadingCompleted()
                }
            case .failure(let error):
                self?.delegate?.onPlaybackOrDownloadingCompleted()
                self?.delegate?.onFailedDownloadingWithError(error)
            }
        }
    }

    fileprivate func startPlaying(_ playbackInfo: PlaybackInfo) {
        prePlayOperation(qari: playbackInfo.qari, startAyah: playbackInfo.startAyah, endAyah: playbackInfo.endAyah) { [weak self] in
            self?.player.play(qari: playbackInfo.qari, startAyah: playbackInfo.startAyah, endAyah: playbackInfo.endAyah)
            self?.delegate?.onPlayingStarted()
        }
    }
}
