//
//  AudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AudioPlayerDelegate {
    func willStartDownloadingAudioFiles(progress progress: NSProgress)
    func onPlayingAyah(ayah: AyahNumber)
}

protocol AudioPlayerInteractor {
    func playAudioForQari(qari: Qari, atPage page: QuranPage)

    func cancelDownload()

    func pauseAudio()
    func resumeAudio()
    func stopAudio()
    func goForward()
    func goBackward()
}
