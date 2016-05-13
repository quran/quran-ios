//
//  GaplessAudioFilesDownloader.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct GaplessAudioFilesDownloader: AudioFilesDownloader {
    func allFilesDownloaded(startAyah startAyah: AyahNumber, endAyah: AyahNumber, completion: (Bool) -> Void) {
        unimplemented()
    }

    func downloadFiles(startAyah startAyah: AyahNumber, endAyah: AyahNumber, completionHandler: Result<(), NetworkError> -> Void) {
        unimplemented()
    }
}
