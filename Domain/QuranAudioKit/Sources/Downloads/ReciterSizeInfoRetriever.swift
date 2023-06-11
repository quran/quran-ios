//
//  ReciterSizeInfoRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//

import Foundation
import QuranKit
import Reciter
import ReciterService
import SystemDependencies
import VLogging

private struct AudioFileLists {
    let gapped: [ReciterAudioFile]
    let gapless: [ReciterAudioFile]
}

public struct ReciterSizeInfoRetriever: Sendable {
    let baseURL: URL
    let fileSystem: FileSystem

    public init(baseURL: URL) {
        self.init(baseURL: baseURL, fileSystem: DefaultFileSystem())
    }

    public init(baseURL: URL, fileSystem: FileSystem = DefaultFileSystem()) {
        self.baseURL = baseURL
        self.fileSystem = fileSystem
    }

    public func getReciterAudioDownloads(for reciters: [Reciter], quran: Quran) async -> [Reciter: ReciterAudioDownload] {
        await withTaskGroup(of: ReciterAudioDownload.self) { group in
            for reciter in reciters {
                group.addTask {
                    await getReciterAudioDownload(for: reciter, quran: quran)
                }
            }

            var downloads: [Reciter: ReciterAudioDownload] = [:]
            for await download in group {
                downloads[download.reciter] = download
            }
            return downloads
        }
    }

    public func getReciterAudioDownload(for reciter: Reciter, quran: Quran) async -> ReciterAudioDownload {
        let fileList = reciter.audioFiles(baseURL: baseURL, from: quran.firstVerse, to: quran.lastVerse)

        guard let fileURLs = try? fileSystem.contentsOfDirectory(at: reciter.localFolder(), includingPropertiesForKeys: [.fileSizeKey]) else {
            return ReciterAudioDownload(reciter: reciter,
                                        downloadedSizeInBytes: 0,
                                        downloadedSuraCount: 0,
                                        surasCount: quran.suras.count)
        }

        // sum the sizes of downloaded files
        let sizeInBytes = sizeInBytes(of: fileURLs)

        // remove suras that we didn't find dowonloaded files for
        let fileURLPaths = Set(fileURLs.map(\.lastPathComponent))
        let fileListsNotDownloaded = fileList.filter { !fileURLPaths.contains($0.local.lastPathComponent) }
        var suras = Set(quran.suras)
        for file in fileListsNotDownloaded {
            // remove the suras from being downloaded.
            // For gapless, that's enough.
            // for gapped, we consider if one ayah is not downloaded that the entire sura is not downloaded.
            if let sura = file.sura {
                suras.remove(sura)
            }
        }

        return ReciterAudioDownload(reciter: reciter,
                                    downloadedSizeInBytes: sizeInBytes,
                                    downloadedSuraCount: suras.count,
                                    surasCount: quran.suras.count)
    }

    private func sizeInBytes(of fileURLs: [URL]) -> UInt64 {
        var sizeInBytes: UInt64 = 0
        for fileURL in fileURLs {
            do {
                let resourceValues = try fileSystem.resourceValues(at: fileURL, forKeys: Set([.fileSizeKey]))
                sizeInBytes += UInt64(resourceValues.fileSize ?? 0)
            } catch {
                logger.error("Unexpected error while getting resourceValues. Error: \(error)")
            }
        }
        return sizeInBytes
    }
}
