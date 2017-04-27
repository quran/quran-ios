//
//  QariAudioFileListRetrieval.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
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

protocol QariAudioFile {
    var remote: URL { get }
    var local: String { get }
}

extension QariAudioFile {
    var hashValue: Int {
        return remote.hashValue
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.remote == rhs.remote
    }
}

struct QariDatabaseAudioFile: QariAudioFile, Hashable {
    let remote: URL
    let local: String
}

struct QariSuraAudioFile: QariAudioFile, Hashable {
    let remote: URL
    let local: String
    let sura: Int
}

protocol QariAudioFileListRetrieval {
    func get(for qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [QariAudioFile]
}

struct GaplessQariAudioFileListRetrieval: QariAudioFileListRetrieval {
    func get(for qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [QariAudioFile] {
        guard case AudioType.gapless(let databaseFileName) = qari.audioType else {
            fatalError("Unsupported qari type gapped. Only gapless qaris can be downloaded here.")
        }

        let databaseRemoteURL = QuranURLs.AudioDatabaseURL.appendingPathComponent(
            databaseFileName).appendingPathExtension(Files.databaseRemoteFileExtension)
        let databaseLocalURL = qari.path.stringByAppendingPath(databaseFileName).stringByAppendingExtension(Files.databaseRemoteFileExtension)
        let dbFile = QariDatabaseAudioFile(remote: databaseRemoteURL, local: databaseLocalURL)

        // loop over the files
        var files = Set<QariSuraAudioFile>()

        for sura in startAyah.sura...endAyah.sura {
            let fileName = sura.as3DigitString()

            let remoteURL = qari.audioURL.appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            let localURL = qari.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.audioExtension)

            files.insert(QariSuraAudioFile(remote: remoteURL, local: localURL, sura: sura))
        }
        return Array(files) + [dbFile]
    }
}

struct GappedQariAudioFileListRetrieval: QariAudioFileListRetrieval {
    func get(for qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> [QariAudioFile] {
        guard case AudioType.gapped = qari.audioType else {
            fatalError("Unsupported qari type gapless. Only gapless qaris can be downloaded here.")
        }

        var files = Set<QariSuraAudioFile>()

        // add besm Allah for all gapped audio
        files.insert(createRequestInfo(qari: qari, sura: 1, ayah: 1))

        for sura in startAyah.sura...endAyah.sura {

            let startAyahNumber = sura == startAyah.sura ? startAyah.ayah : 1
            let endAyahNumber = sura == endAyah.sura ? endAyah.ayah : Quran.numberOfAyahsForSura(sura)

            for ayah in startAyahNumber...endAyahNumber {
                files.insert(createRequestInfo(qari: qari, sura: sura, ayah: ayah))
            }
        }
        return Array(files)
    }

    private func createRequestInfo(qari: Qari, sura: Int, ayah: Int) -> QariSuraAudioFile {
        let fileName = sura.as3DigitString() + ayah.as3DigitString()
        let remoteURL = qari.audioURL.appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
        let localURL = qari.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.audioExtension)
        return QariSuraAudioFile(remote: remoteURL, local: localURL, sura: sura)
    }
}
