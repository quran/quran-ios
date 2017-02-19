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

    func prePlayOperation(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, completion: @escaping () -> Void)
}

extension DefaultAudioPlayerInteractor {

    fileprivate typealias PlaybackInfo = (qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber)

    func prePlayOperation(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, completion: @escaping () -> Void) {
        completion()
    }

    func checkIfDownloading(_ completion: @escaping (_ downloading: Bool) -> Void) {
        downloader.getCurrentDownloadRequest { [weak self] (request) in
            guard let request = request else {
                completion(false)
                return
            }
            self?.gotDownloadRequest(request, playbackInfo: nil)
            completion(true)
        }
    }

    func playAudioForQari(_ qari: Qari, atPage page: QuranPage) {

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
                        self.gotDownloadRequest(request, playbackInfo: (qari: qari, startAyah: startAyah, endAyah: endAyah))
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

    fileprivate func gotDownloadRequest(_ response: Response, playbackInfo: PlaybackInfo?) {

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
