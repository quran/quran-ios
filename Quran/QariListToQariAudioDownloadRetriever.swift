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

class QariListToQariAudioDownloadRetriever: Interactor {

    let fileListCreator: AnyCreator<Qari, QariAudioFileListRetrieval>
    init(fileListCreator: AnyCreator<Qari, QariAudioFileListRetrieval>) {
        self.fileListCreator = fileListCreator
    }

    func execute(_ qaris: [Qari]) -> Promise<[QariAudioDownload]> {
        return Promise(value: qaris)
                .map(execute: self.createAudioDownload(for:))
    }

    private func createAudioDownload(for qari: Qari) -> QariAudioDownload {

        // get the list of files for the entire Quran.
        let fileList = fileListCreator.create(qari).get(for: qari, startAyah: Quran.startAyah, endAyah: Quran.lastAyah)

        let manager = FileManager.default

        var suras = Set(Sura.getSuras().map { $0.suraNumber })

        // sum the sizes of downloaded files
        var sizeInBytes: UInt64 = 0
        for file in fileList {
            let localPath = FileManager.documentsPath.stringByAppendingPath(file.local)
            if manager.fileExists(atPath: localPath) {
                // calculate the size

                let attributes = (try? manager.attributesOfItem(atPath: localPath)) ?? [:]
                let size = attributes[.size] as? UInt64
                sizeInBytes += size ?? 0
            } else {
                // remove the sura from being downloaded.
                // For gapless, that's enough.
                // for gapped, we consider if one ayah is not downloaded that the entire sura is not downloaded.
                if let file = file as? QariSuraAudioFile {
                    suras.remove(file.sura)
                }
            }
        }
        return QariAudioDownload(qari: qari, downloadedSizeInBytes: sizeInBytes, downloadedSuraCount: suras.count)
    }
}
