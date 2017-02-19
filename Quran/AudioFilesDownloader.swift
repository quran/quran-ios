//
//  AudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol AudioFilesDownloader: class {

    func cancel()
    func resume()
    func suspend()

    func needsToDownloadFiles(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Bool

    func getCurrentDownloadResponse() -> Response?

    func download(qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber) -> Response?
}
