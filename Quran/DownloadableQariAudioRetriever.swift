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

import PromiseKit

class DownloadableQariAudioRetriever: Interactor {

    private let qarisRetriever: AnyGetInteractor<[Qari]>
    private let downloadsInfoRetriever: AnyInteractor<[Qari], [QariAudioDownload]>
    private let downloader: DownloadManager

    init(downloader: DownloadManager, qarisRetriever: AnyGetInteractor<[Qari]>, downloadsInfoRetriever: AnyInteractor<[Qari], [QariAudioDownload]>) {
        self.downloader             = downloader
        self.qarisRetriever         = qarisRetriever
        self.downloadsInfoRetriever = downloadsInfoRetriever
    }

    func execute(_ p: Void) -> Promise<[DownloadableQariAudio]> {
        let retriever = qarisRetriever
            .get()
            .then(execute: downloadsInfoRetriever.execute)

        let downloads = downloader.getOnGoingDownloads()
        return when(fulfilled: downloads, retriever).then(execute: createDownloadableQariAudio(downloads:qaris:))
    }

    private func createDownloadableQariAudio(downloads: [DownloadNetworkBatchResponse], qaris: [QariAudioDownload]) -> [DownloadableQariAudio] {

        var paths: [String: DownloadNetworkBatchResponse] = [:]
        for batch in downloads {
            if let download = batch.responses.first, batch.isAudio {
                if let path = download.download.destinationPath.pathComponents.first(where: { "/" != $0 }) {
                    paths[path] = batch
                }
            }
        }

        return qaris.map { audio in
            let response: Response?
            if let batch =  paths[audio.qari.path] {
                response = CollectionResponse(responses: batch.responses)
            } else {
                response = nil
            }
            return DownloadableQariAudio(audio: audio, response: response)
        }
    }
}
