//
//  AudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
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
import PromiseKit
import QueuePlayer

protocol AudioPlayerInteractorDelegate: class {
    func willStartDownloading()
    func didStartDownloadingAudioFiles(progress: QProgress)

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
    func isAudioDownloading() -> Promise<Bool>

    func playAudioForQari(_ qari: Qari, range: VerseRange)
    func getAyahRange(starting startAyah: AyahNumber, page: QuranPage) -> VerseRange

    func cancelDownload()

    func pauseAudio()
    func resumeAudio()
    func stopAudio()
    func goForward()
    func goBackward()
    func setVerseRuns(_ runs: Runs)
    func setListRuns(_ runs: Runs)
}
