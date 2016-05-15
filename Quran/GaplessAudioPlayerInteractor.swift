//
//  GaplessAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class GaplessAudioPlayerInteractor: AudioPlayerInteractor {

    weak var delegate: AudioPlayerInteractorDelegate? = nil

    let downloader: AudioFilesDownloader

    let lastAyahFinder: LastAyahFinder

    init(downloader: AudioFilesDownloader, lastAyahFinder: LastAyahFinder) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
    }

    func checkIfDownloading(completion: (downloading: Bool) -> Void) {
        downloader.getCurrentDownloadRequest { [weak self] (request) in
            guard let request = request else {
                completion(downloading: false)
                return
            }
            self?.gotDownloadRequest(request)
            completion(downloading: true)
        }
    }

    func playAudioForQari(qari: Qari, atPage page: QuranPage) {

        let startAyah = Quran.startAyahForPage(page.pageNumber)
        let endAyah = lastAyahFinder.findLastAyah(startAyah: startAyah, page: page.pageNumber)

        if let request = downloader.download(qari: qari, startAyah: startAyah, endAyah: endAyah) {
            print("downloading")
            gotDownloadRequest(request)
        } else {
            print("playing audio")
            delegate?.onPlayingAyah(startAyah)
        }
    }

    func cancelDownload() {
        downloader.cancel()
    }

    func pauseAudio() {
        downloader.suspend()
    }

    func resumeAudio() {
        downloader.resume()
    }

    func stopAudio() {
        downloader.cancel()
    }

    func goForward() {
        unimplemented()
    }

    func goBackward() {
        unimplemented()
    }

    private func gotDownloadRequest(request: Request) {
        delegate?.willStartDownloadingAudioFiles(progress: request.progress)
        request.onCompletion = { [weak self] result in
            switch result {
            case .Success:
                self?.delegate?.onPlayingAyah(AyahNumber(sura: 0, ayah: 0))
            case .Failure(let error):
                self?.delegate?.onFailedDownloadingWithError(error)
            }
        }
    }
}
