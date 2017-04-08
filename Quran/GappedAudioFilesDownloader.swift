//
//  GappedAudioFilesDownloader.swift
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

class GappedAudioFilesDownloader: DefaultAudioFilesDownloader {

    let downloader: DownloadManager

    var response: Response?

    init(downloader: DownloadManager) {
        self.downloader = downloader
    }

    func filesForQari(_ qari: Qari,
                      startAyah: AyahNumber,
                      endAyah: AyahNumber) -> [Download] {

        guard case AudioType.gapped = qari.audioType else {
            fatalError("Unsupported qari type gapless. Only gapless qaris can be downloaded here.")
        }

        var files: [Download] = []

        // add besm Allah for all gapped
        files.append(createRequestInfo(qari: qari, sura: 1, ayah: 1))

        for sura in startAyah.sura...endAyah.sura {

            let startAyahNumber = sura == startAyah.sura ? startAyah.ayah : 1
            let endAyahNumber = sura == endAyah.sura ? endAyah.ayah : Quran.numberOfAyahsForSura(sura)

            for ayah in startAyahNumber...endAyahNumber {
                files.append(createRequestInfo(qari: qari, sura: sura, ayah: ayah))
            }
        }

        return files
    }

    fileprivate func createRequestInfo(qari: Qari, sura: Int, ayah: Int) -> Download {
        let fileName = String(format: "%03d%03d", sura, ayah)
        let remoteURL = qari.audioURL.appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
        let localURL = qari.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.audioExtension)
        let resumeURL = localURL.stringByAppendingExtension(Files.downloadResumeDataExtension)
        return Download(url: remoteURL, resumePath: resumeURL, destinationPath: localURL)
    }
}
