//
//  AudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AudioPlayerInteractorDelegate: class {
    func willStartDownloading()
    func didStartDownloadingAudioFiles(progress progress: NSProgress)

    func onPlayingAyah(ayah: AyahNumber)

    func onFailedDownloadingWithError(error: ErrorType)

    func onPlaybackDownloadingCompleted()
}

protocol AudioPlayerInteractor: class {

    weak var delegate: AudioPlayerInteractorDelegate? { get set }

    // will call willStartDownloadingAudioFiles if there is downloads
    func checkIfDownloading(completion: (downloading: Bool) -> Void)

    func playAudioForQari(qari: Qari, atPage page: QuranPage)

    func cancelDownload()

    func pauseAudio()
    func resumeAudio()
    func stopAudio()
    func goForward()
    func goBackward()
}
