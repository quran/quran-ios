//
//  AudioDownloadedSize.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import QuranKit

public struct AudioDownloadedSize: Hashable, Sendable {
    // MARK: Lifecycle

    public init(downloadedSizeInBytes: UInt64, downloadedSuraCount: Int, surasCount: Int) {
        self.downloadedSizeInBytes = downloadedSizeInBytes
        self.downloadedSuraCount = downloadedSuraCount
        self.surasCount = surasCount
    }

    // MARK: Public

    public let downloadedSizeInBytes: UInt64
    public let downloadedSuraCount: Int
    public let surasCount: Int

    public var isDownloaded: Bool {
        downloadedSuraCount == surasCount
    }

    public static func zero(quran: Quran) -> AudioDownloadedSize {
        AudioDownloadedSize(
            downloadedSizeInBytes: 0,
            downloadedSuraCount: 0,
            surasCount: quran.suras.count
        )
    }
}
