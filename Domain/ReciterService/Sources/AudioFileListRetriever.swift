//
//  AudioFileListRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//

import Foundation
import QuranKit

public struct ReciterAudioFile: Sendable, Hashable {
    public var remote: URL
    public var local: String
    public var sura: Sura? = nil
}

protocol AudioFileListRetriever {
    func get(for reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [ReciterAudioFile]
}

struct GaplessAudioFileListRetriever: AudioFileListRetriever {
    let baseURL: URL

    func get(for reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [ReciterAudioFile] {
        guard let databaseRemoteURL = reciter.databaseRemoteURL(baseURL: baseURL),
              let databaseLocalPath = reciter.localDatabasePath
        else {
            fatalError("Unsupported reciter type gapped. Only gapless reciters can be downloaded here.")
        }

        let dbFile = ReciterAudioFile(remote: databaseRemoteURL, local: databaseLocalPath)

        // loop over the files
        var files = Set<ReciterAudioFile>()

        for sura in start.sura.array(to: end.sura) {
            let remoteURL = reciter.remoteURL(sura: sura)
            let localPath = reciter.localPath(sura: sura)
            files.insert(ReciterAudioFile(remote: remoteURL, local: localPath, sura: sura))
        }
        return Array(files) + [dbFile]
    }
}

struct GappedAudioFileListRetriever: AudioFileListRetriever {
    func get(for reciter: Reciter, from start: AyahNumber, to end: AyahNumber) -> [ReciterAudioFile] {
        guard case AudioType.gapped = reciter.audioType else {
            fatalError("Unsupported reciter type gapless. Only gapless reciters can be downloaded here.")
        }

        var files = Set<ReciterAudioFile>()

        // add besm Allah for all gapped audio
        files.insert(createRequestInfo(reciter: reciter, ayah: start.quran.firstVerse))

        for ayah in start.array(to: end) {
            files.insert(createRequestInfo(reciter: reciter, ayah: ayah))
        }
        return Array(files)
    }

    private func createRequestInfo(reciter: Reciter, ayah: AyahNumber) -> ReciterAudioFile {
        let remoteURL = reciter.remoteURL(ayah: ayah)
        let localPath = reciter.localPath(ayah: ayah)
        return ReciterAudioFile(remote: remoteURL, local: localPath, sura: ayah.sura)
    }
}

extension Reciter {
    public func audioFiles(baseURL: URL, from: AyahNumber, to: AyahNumber) -> [ReciterAudioFile] {
        let retriever = retriever(baseURL: baseURL)
        return retriever.get(for: self, from: from, to: to)
    }

    private func retriever(baseURL: URL) -> AudioFileListRetriever {
        switch audioType {
        case .gapped: return GappedAudioFileListRetriever()
        case .gapless: return GaplessAudioFileListRetriever(baseURL: baseURL)
        }
    }
}
