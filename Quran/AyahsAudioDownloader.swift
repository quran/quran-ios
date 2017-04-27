//
//  AyahsAudioDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/21/17.
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

struct AyahsAudioDownloadRequest {
    let start: AyahNumber
    let end: AyahNumber
    let qari: Qari
}

struct AyahsAudioDownloader: Interactor {

    let downloader: DownloadManager
    let creator: AnyCreator<QariAudioFileListRetrieval, Qari>
    init(downloader: DownloadManager, creator: AnyCreator<QariAudioFileListRetrieval, Qari>) {
        self.downloader = downloader
        self.creator = creator
    }

    func execute(_ request: AyahsAudioDownloadRequest) -> Promise<[DownloadNetworkResponse]> {
        return DispatchQueue.default.promise2 { () -> [DownloadNetworkResponse] in
            let retriever = self.creator.create(request.qari)

            // get downloads
            let files = retriever
                .get(for: request.qari, startAyah: request.start, endAyah: request.end)
                .filter { !FileManager.documentsURL.appendingPathComponent($0.local).isReachable }
                .map { Download(url: $0.remote, resumePath: $0.local.resumePath, destinationPath: $0.local) }
                .map { DownloadRequest( method: .GET, download: $0) }

            // create downloads
            let responses = self.downloader.download(files)
            return responses
        }
    }
}
