//
//  DownloadedRecitersService.swift
//
//
//  Created by Zubair Khan on 12/31/22.
//

import Foundation

public class DownloadedRecitersService {
    public init() {
    }

    public func downloadedReciters(_ allReciters: [Reciter]) -> [Reciter] {
        guard let downloadedRecitersPaths = try? FileManager.default.contentsOfDirectory(
            at: Reciter.audioFiles,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        var downloadedReciters: [Reciter] = []
        for reciter in allReciters {
            for downloadedReciterPath in downloadedRecitersPaths {
                if isDownloadedReciter(reciter, downloadedReciterPath) {
                    downloadedReciters.append(reciter)
                }
            }
        }
        return downloadedReciters
    }

    private func isDownloadedReciter(_ reciter: Reciter, _ downloadedReciterPath: URL) -> Bool {
        let downloadedReciterDir = downloadedReciterPath.lastPathComponent

        if reciter.directory == downloadedReciterDir {
            // ensure the reciter's directory is not empty and has some downloads
            if let reciterDirContents = try? FileManager.default.contentsOfDirectory(
                at: downloadedReciterPath,
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
