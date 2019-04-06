//
//  DownloadableQariAudioRetriever.swift
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
import BatchDownloader
import PromiseKit

protocol DownloadableQariAudioRetrieverType {
    func getDownloadableQariAudios() -> Guarantee<[DownloadableQariAudio]>
}

class DownloadableQariAudioRetriever: DownloadableQariAudioRetrieverType {

    private let qarisRetriever: QariDataRetrieverType
    private let downloadsInfoRetriever: QariListToQariAudioDownloadRetrieverType
    private let downloader: DownloadManager

    init(downloader: DownloadManager, qarisRetriever: QariDataRetrieverType, downloadsInfoRetriever: QariListToQariAudioDownloadRetrieverType) {
        self.downloader             = downloader
        self.qarisRetriever         = qarisRetriever
        self.downloadsInfoRetriever = downloadsInfoRetriever
    }

    func getDownloadableQariAudios() -> Guarantee<[DownloadableQariAudio]> {
        let retriever = qarisRetriever
            .getQaris()
            .then(downloadsInfoRetriever.getQariAudioDownloads(for:))

        let downloads = downloader.getOnGoingDownloads()
        return when(downloads, retriever).map(createDownloadableQariAudio(downloads:qaris:))
    }

    private func createDownloadableQariAudio(downloads: [DownloadBatchResponse], qaris: [QariAudioDownload]) -> [DownloadableQariAudio] {

        var paths: [String: DownloadBatchResponse] = [:]
        for batch in downloads {
            if let download = batch.requests.first, batch.isAudio {
                if let path = download.destinationPath.pathComponents.first(where: { "/" != $0 }) {
                    paths[path] = batch
                }
            }
        }

        return qaris.map { audio in
            return DownloadableQariAudio(audio: audio, response: paths[audio.qari.path])
        }
    }
}
