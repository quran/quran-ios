//
//  DownloadedRecitersService.swift
//
//
//  Created by Zubair Khan on 12/31/22.
//

import Foundation
import QuranAudio

public class DownloadedRecitersService {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func downloadedReciters(_ allReciters: [Reciter]) -> [Reciter] {
        guard let downloadedRecitersURLs = try? FileManager.default.contentsOfDirectory(
            at: Reciter.audioFiles,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        var downloadedReciters: [Reciter] = []
        for reciter in allReciters {
            for downloadedReciterURL in downloadedRecitersURLs {
                if isDownloadedReciter(reciter, at: downloadedReciterURL) {
                    downloadedReciters.append(reciter)
                }
            }
        }
        return downloadedReciters
    }

    // MARK: Private

    private func isDownloadedReciter(_ reciter: Reciter, at downloadedReciterURL: URL) -> Bool {
        if reciter.isReciterDirectory(downloadedReciterURL) {
            // ensure the reciter's directory is not empty and has some downloads
            if let reciterDirContents = try? FileManager.default.contentsOfDirectory(
                at: downloadedReciterURL,
                includingPropertiesForKeys: nil
            ) {
                if !reciterDirContents.isEmpty {
                    return true
                }
            }
        }
        return false
    }
}
