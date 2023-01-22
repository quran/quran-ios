//
//  ReciterAudioFileListRetrieval.swift
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
import QuranKit

protocol ReciterAudioFile {
    var remote: URL { get }
    var local: String { get }
}

extension ReciterAudioFile {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.remote == rhs.remote
    }
}

struct ReciterDatabaseAudioFile: ReciterAudioFile, Hashable {
    let remote: URL
    let local: String
}

struct ReciterSuraAudioFile: ReciterAudioFile, Hashable {
    let remote: URL
    let local: String
    let sura: Sura
}

protocol ReciterAudioFileListRetrieval {
    func get(for reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [ReciterAudioFile]
}

struct GaplessReciterAudioFileListRetrieval: ReciterAudioFileListRetrieval {
    let baseURL: URL

    private let path = "hafs/databases/audio/"
    var audioDatabaseURL: URL { baseURL.appendingPathComponent(path) }

    func get(for reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [ReciterAudioFile] {
        guard case AudioType.gapless(let databaseFileName) = reciter.audioType else {
            fatalError("Unsupported reciter type gapped. Only gapless reciters can be downloaded here.")
        }

        let databaseRemoteURL = audioDatabaseURL.appendingPathComponent(databaseFileName)
            .appendingPathExtension(Files.databaseRemoteFileExtension)
        let databaseLocalURL = reciter.path.stringByAppendingPath(databaseFileName).stringByAppendingExtension(Files.databaseRemoteFileExtension)
        let dbFile = ReciterDatabaseAudioFile(remote: databaseRemoteURL, local: databaseLocalURL)

        // loop over the files
        var files = Set<ReciterSuraAudioFile>()

        for sura in start.sura.array(to: end.sura) {
            let fileName = sura.suraNumber.as3DigitString()

            let remoteURL = reciter.audioURL.appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
            let localURL = reciter.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.audioExtension)

            files.insert(ReciterSuraAudioFile(remote: remoteURL, local: localURL, sura: sura))
        }
        return Array(files) + [dbFile]
    }
}

struct GappedReciterAudioFileListRetrieval: ReciterAudioFileListRetrieval {
    let quran: Quran

    func get(for reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [ReciterAudioFile] {
        guard case AudioType.gapped = reciter.audioType else {
            fatalError("Unsupported reciter type gapless. Only gapless reciters can be downloaded here.")
        }

        var files = Set<ReciterSuraAudioFile>()

        // add besm Allah for all gapped audio
        files.insert(createRequestInfo(reciter: reciter, sura: quran.firstSura, ayah: 1))

        for ayah in start.array(to: end) {
            files.insert(createRequestInfo(reciter: reciter, sura: ayah.sura, ayah: ayah.ayah))
        }
        return Array(files)
    }

    private func createRequestInfo(reciter: Reciter, sura: Sura, ayah: Int) -> ReciterSuraAudioFile {
        let fileName = sura.suraNumber.as3DigitString() + ayah.as3DigitString()
        let remoteURL = reciter.audioURL.appendingPathComponent(fileName).appendingPathExtension(Files.audioExtension)
        let localURL = reciter.path.stringByAppendingPath(fileName).stringByAppendingExtension(Files.audioExtension)
        return ReciterSuraAudioFile(remote: remoteURL, local: localURL, sura: sura)
    }
}
