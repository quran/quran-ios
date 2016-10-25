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
    func didStartDownloadingAudioFiles(progress: Foundation.Progress)

    func onPlayingStarted()

    func onPlaybackPaused()

    func onPlaybackResumed()

    func highlight(_ ayah: AyahNumber)

    func onFailedDownloadingWithError(_ error: Error)

    func onPlaybackOrDownloadingCompleted()
}

protocol AudioPlayerInteractor: class {

    weak var delegate: AudioPlayerInteractorDelegate? { get set }

    // will call willStartDownloadingAudioFiles if there is downloads
    func checkIfDownloading(_ completion: @escaping (_ downloading: Bool) -> Void)

    func playAudioForQari(_ qari: Qari, atPage page: QuranPage)

    func cancelDownload()

    func pauseAudio()
    func resumeAudio()
    func stopAudio()
    func goForward()
    func goBackward()
}
