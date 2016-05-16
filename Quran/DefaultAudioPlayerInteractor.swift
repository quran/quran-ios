//
//  DefaultAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/16/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol DefaultAudioPlayerInteractor: AudioPlayerInteractor, AudioPlayerDelegate {

    var downloader: AudioFilesDownloader { get }

    var player: AudioPlayer { get }

    var lastAyahFinder: LastAyahFinder { get }

    var downloadCancelled: Bool { get set }
}

extension DefaultAudioPlayerInteractor {

    private typealias PlaybackInfo = (qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber)

    func checkIfDownloading(completion: (downloading: Bool) -> Void) {
        downloader.getCurrentDownloadRequest { [weak self] (request) in
            guard let request = request else {
                completion(downloading: false)
                return
            }
            self?.gotDownloadRequest(request, playbackInfo: nil)
            completion(downloading: true)
        }
    }

    func playAudioForQari(qari: Qari, atPage page: QuranPage) {

        let startAyah = Quran.startAyahForPage(page.pageNumber)
        let endAyah = lastAyahFinder.findLastAyah(startAyah: startAyah, page: page.pageNumber)

        if downloader.needsToDownloadFiles(qari: qari, startAyah: startAyah, endAyah: endAyah) {
            downloadCancelled = false
            Queue.background.async {
                self.delegate?.willStartDownloading()
                if let request = self.downloader.download(qari: qari, startAyah: startAyah, endAyah: endAyah) {
                    if self.downloadCancelled {
                        request.cancel()
                    } else {
                        print("downloading")
                        self.gotDownloadRequest(request, playbackInfo: (qari: qari, startAyah: startAyah, endAyah: endAyah))
                    }
                }
            }
        } else {
            print("playing audio")
            player.play(qari: qari, startAyah: startAyah, endAyah: endAyah)
            startPlaying(qari: qari, startAyah: startAyah, endAyah: endAyah)
            delegate?.onPlayingAyah(startAyah)
        }
    }

    func cancelDownload() {
        downloadCancelled = true
        downloader.cancel()
        delegate?.onPlaybackDownloadingCompleted()
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

    // MARK:- AudioPlayerDelegate

    func onPlaybackEnded() {
        delegate?.onPlaybackDownloadingCompleted()
    }

    func playingAyah(ayah: AyahNumber) {
        // highlight the ayah
    }

    private func gotDownloadRequest(request: Request, playbackInfo: PlaybackInfo?) {

        delegate?.didStartDownloadingAudioFiles(progress: request.progress)
        request.onCompletion = { [weak self] result in
            switch result {
            case .Success:
                if let playbackInfo = playbackInfo {
                    self?.startPlaying(playbackInfo)
                } else {
                    self?.delegate?.onPlaybackDownloadingCompleted()
                }
            case .Failure(let error):
                self?.delegate?.onPlaybackDownloadingCompleted()
                self?.delegate?.onFailedDownloadingWithError(error)
            }
        }
    }

    private func startPlaying(playbackInfo: PlaybackInfo) {
        delegate?.onPlayingAyah(AyahNumber(sura: 0, ayah: 0))
        player.play(qari: playbackInfo.qari, startAyah: playbackInfo.startAyah, endAyah: playbackInfo.endAyah)
    }
}
