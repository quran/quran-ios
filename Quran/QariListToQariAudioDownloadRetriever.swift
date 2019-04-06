//
//  QariListToQariAudioDownloadRetriever.swift
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

import PromiseKit

private struct AudioFileLists {
    let gapped: [QariAudioFile]
    let gapless: [QariAudioFile]
}

protocol QariListToQariAudioDownloadRetrieverType {
    func getQariAudioDownloads(for qaris: [Qari]) -> Guarantee<[QariAudioDownload]>
}

class QariListToQariAudioDownloadRetriever: QariListToQariAudioDownloadRetrieverType {

    let fileListCreator: AnyCreator<Qari, QariAudioFileListRetrieval>
    init(fileListCreator: AnyCreator<Qari, QariAudioFileListRetrieval>) {
        self.fileListCreator = fileListCreator
    }

    func getQariAudioDownloads(for qaris: [Qari]) -> Guarantee<[QariAudioDownload]> {
        let suras = DispatchQueue.global().async(.promise) {
            Set(Sura.getSuras().map { $0.suraNumber })
        }
        let fileLists = DispatchQueue.global().async(.promise) {
            self.createFileLists(for: qaris)
        }
        let qarisAndSuras = when(suras, fileLists)
            .map { suras, fileLists in qaris.map { q in (q, suras, fileLists) } }
        return qarisAndSuras.parallelMap(execute: self.createAudioDownload(for:suras:fileLists:))
    }

    private func createFileLists(for qaris: [Qari]) -> AudioFileLists {
        let gapped = qaris.first(where: {
            if case .gapped = $0.audioType {
                return true
            }
            return false
        })

        let gapless = qaris.first(where: {
            if case .gapless = $0.audioType {
                return true
            }
            return false
        })

        let gappedList: [QariAudioFile]
        if let qari = gapped {
            gappedList = fileListCreator.create(qari).get(for: qari, range: VerseRange(lowerBound: Quran.startAyah, upperBound: Quran.lastAyah))
        } else {
            gappedList = []
        }

        let gaplessList: [QariAudioFile]
        if let qari = gapless {
            gaplessList = fileListCreator.create(qari).get(for: qari, range: VerseRange(lowerBound: Quran.startAyah, upperBound: Quran.lastAyah))
        } else {
            gaplessList = []
        }
        return AudioFileLists(gapped: gappedList, gapless: gaplessList)
    }

    private func createAudioDownload(for qari: Qari, suras: Set<Int>, fileLists: AudioFileLists) -> QariAudioDownload {
        // get the list of files for the entire Quran.
        let fileList: [QariAudioFile]
        switch qari.audioType {
        case .gapped: fileList = fileLists.gapped
        case .gapless: fileList = fileLists.gapless
        }

        let manager = FileManager.default
        var filesDictionary = fileList.flatGroup { $0.local.lastPathComponent }

        let properties: [URLResourceKey] = [.fileSizeKey]

        guard let enumerator = manager.enumerator(at: qari.localFolder(), includingPropertiesForKeys: properties, options: []) else {
            return QariAudioDownload(qari: qari, downloadedSizeInBytes: 0, downloadedSuraCount: 0)
        }

        // sum the sizes of downloaded files
        var sizeInBytes: UInt64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set([.fileSizeKey]))
                sizeInBytes += UInt64(resourceValues.fileSize ?? 0)
                let path = fileURL.lastPathComponent
                filesDictionary[path] = nil
            } catch {
                CLog("Unexpected error while getting resourceValues", error)
            }
        }

        // remove suras that we didn't find dowonloaded files for
        var suras = suras
        for (_, file) in filesDictionary {
            // remove the suras from being downloaded.
            // For gapless, that's enough.
            // for gapped, we consider if one ayah is not downloaded that the entire sura is not downloaded.
            if let file = file as? QariSuraAudioFile {
                suras.remove(file.sura)
            }
        }

        return QariAudioDownload(qari: qari, downloadedSizeInBytes: sizeInBytes, downloadedSuraCount: suras.count)
    }
}
