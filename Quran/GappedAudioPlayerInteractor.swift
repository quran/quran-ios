//
//  GappedAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

class GappedAudioPlayerInteractor: DefaultAudioPlayerInteractor {

    weak var delegate: AudioPlayerInteractorDelegate? = nil

    let downloader: AudioFilesDownloader

    let lastAyahFinder: LastAyahFinder

    init(downloader: AudioFilesDownloader, lastAyahFinder: LastAyahFinder) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
    }
}
