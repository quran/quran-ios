//
//  ReciterAudioDownload.swift
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

import QuranAudio

public struct ReciterAudioDownload: Equatable, Sendable {
    // MARK: Lifecycle

    public init(reciter: Reciter, downloadedSizeInBytes: UInt64, downloadedSuraCount: Int, surasCount: Int) {
        self.reciter = reciter
        self.downloadedSizeInBytes = downloadedSizeInBytes
        self.downloadedSuraCount = downloadedSuraCount
        self.surasCount = surasCount
    }

    // MARK: Public

    public let reciter: Reciter
    public let downloadedSizeInBytes: UInt64
    public let downloadedSuraCount: Int
    public let surasCount: Int

    public var isDownloaded: Bool {
        downloadedSuraCount == surasCount
    }
}
