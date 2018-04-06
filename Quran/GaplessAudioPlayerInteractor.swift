//
//  GaplessAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
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
import Zip

class GaplessAudioPlayerInteractor: DefaultAudioPlayerInteractor {

    weak var delegate: AudioPlayerInteractorDelegate?

    let downloader: AudioFilesDownloader

    let player: AudioPlayer

    let lastAyahFinder: LastAyahFinder

    var downloadCancelled: Bool = false

    init(downloader: AudioFilesDownloader, lastAyahFinder: LastAyahFinder, player: AudioPlayer) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
        self.player = player
        self.player.delegate = self
    }

    func prePlayOperation(qari: Qari, range: VerseRange, completion: @escaping () -> Void) {
        guard case .gapless(let databaseName) = qari.audioType else {
            fatalError("Unsupported qari type gapped")
        }
        let baseFileName = qari.localFolder().appendingPathComponent(databaseName)
        let dbFile = baseFileName.appendingPathExtension(Files.databaseLocalFileExtension)
        let zipFile = baseFileName.appendingPathExtension(Files.databaseRemoteFileExtension)

        guard !dbFile.isReachable else {
            completion()
            return
        }

        Queue.background.async {
            do {
                try Zip.unzipFile(zipFile, destination: qari.localFolder(), overwrite: true, password: nil, progress: nil)
            } catch {
                Crash.recordError(error, reason: "Cannot unzip file '\(zipFile)' to '\(qari.localFolder())'")
                // delete the zip and try to re-download it again, next time.
                try? FileManager.default.removeItem(at: zipFile)
            }

            Queue.main.async {
                completion()
            }
        }
    }
}
