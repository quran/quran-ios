//
//  ReciterSizeInfoRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//

import Foundation
import PromiseKit
import QuranKit
import VLogging

private struct AudioFileLists {
    let gapped: [ReciterAudioFile]
    let gapless: [ReciterAudioFile]
}

public struct ReciterSizeInfoRetriever {
    let fileListFactory: ReciterAudioFileListRetrievalFactory
    let fileSystem: FileSystem

    public init(baseURL: URL) {
        self.init(baseURL: baseURL, fileSystem: DefaultFileSystem())
    }

    init(baseURL: URL, fileSystem: FileSystem) {
        self.fileSystem = fileSystem
        fileListFactory = DefaultReciterAudioFileListRetrievalFactory(baseURL: baseURL)
    }

    public func getReciterAudioDownloads(for reciters: [Reciter], quran: Quran) async -> [Reciter: ReciterAudioDownload] {
        return await withTaskGroup(of: ReciterAudioDownload.self) { group in
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
        let retriever = fileListFactory.fileListRetrievalForReciter(reciter)
        let fileList = retriever.get(for: reciter, from: quran.firstVerse, to: quran.lastVerse)

        guard let fileURLs = try? fileSystem.contentsOfDirectory(at: reciter.localFolder(), includingPropertiesForKeys: [.fileSizeKey]) else {
            return ReciterAudioDownload(reciter: reciter,
                                        downloadedSizeInBytes: 0,
                                        downloadedSuraCount: 0,
                                        surasCount: quran.suras.count)
        }

        // sum the sizes of downloaded files
        let sizeInBytes = sizeInBytes(of: fileURLs)

        // remove suras that we didn't find dowonloaded files for
        let fileURLPaths = Set(fileURLs.map { $0.lastPathComponent })
        let fileListsNotDownloaded = fileList.filter { !fileURLPaths.contains($0.local.lastPathComponent) }
        var suras = Set(quran.suras)
        for file in fileListsNotDownloaded {
            // remove the suras from being downloaded.
            // For gapless, that's enough.
            // for gapped, we consider if one ayah is not downloaded that the entire sura is not downloaded.
            if let file = file as? ReciterSuraAudioFile {
                suras.remove(file.sura)
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
