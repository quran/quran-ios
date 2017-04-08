//
//  GaplessAudioFilesDownloader.swift
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

class GaplessAudioFilesDownloader: DefaultAudioFilesDownloader {

    let downloader: DownloadManager

    var response: Response?

    init(downloader: DownloadManager) {
        self.downloader = downloader
    }

    func filesForQari(_ qari: Qari,
                      startAyah: AyahNumber,
                      endAyah: AyahNumber) -> [Download] {

        guard case AudioType.gapless(let databaseFileName) = qari.audioType else {
            fatalError("Unsupported qari type gapped. Only gapless qaris can be downloaded here.")
        }

        let databaseRemoteURL = QuranURLs.AudioDatabaseURL.appendingPathComponent(
            databaseFileName).appendingPathExtension(Files.databaseRemoteFileExtension)
        let databaseLocalURL = qari.path.stringByAppendingPath(
            databaseFileName).stringByAppendingExtension(Files.databaseRemoteFileExtension)
        let databaseResumeURL = databaseLocalURL.stringByAppendingExtension(Files.downloadResumeDataExtension)

        // loop over the files
        var files: [Download] = []
        files.append(Download(url: databaseRemoteURL, resumePath: databaseResumeURL, destinationPath: databaseLocalURL))

        for sura in startAyah.sura...endAyah.sura {
            let fileName = String(format: "%03d", sura)

            let remoteURL = qari.audioURL.appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            let localURL = qari.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.audioExtension)
            let resumeURL = localURL.stringByAppendingExtension(Files.downloadResumeDataExtension)

            files.append(Download(url: remoteURL, resumePath: resumeURL, destinationPath: localURL))
        }
        return files
    }
}
