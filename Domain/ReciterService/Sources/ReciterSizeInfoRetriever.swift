//
//  ReciterSizeInfoRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
//

import Foundation
import QuranAudio
import QuranKit
import SystemDependencies
import VLogging

private struct AudioFileLists {
    let gapped: [ReciterAudioFile]
    let gapless: [ReciterAudioFile]
}

public struct ReciterSizeInfoRetriever: Sendable {
    // MARK: Lifecycle

    public init(baseURL: URL) {
        self.init(baseURL: baseURL, fileSystem: DefaultFileSystem())
    }

    public init(baseURL: URL, fileSystem: FileSystem = DefaultFileSystem()) {
        self.baseURL = baseURL
        self.fileSystem = fileSystem
    }

    // MARK: Public

    public func getDownloadedSizes(for reciters: [Reciter], quran: Quran) async -> [Reciter: AudioDownloadedSize] {
        await withTaskGroup(of: (Reciter, AudioDownloadedSize).self) { group in
            for reciter in reciters {
                group.addTask {
                    (reciter, await getDownloadedSize(for: reciter, quran: quran))
                }
            }

            var downloads: [Reciter: AudioDownloadedSize] = [:]
            for await download in group {
                downloads[download.0] = download.1
            }
            return downloads
        }
    }

    public func getDownloadedSize(for reciter: Reciter, quran: Quran) async -> AudioDownloadedSize {
        let fileList = reciter.audioFiles(baseURL: baseURL, from: quran.firstVerse, to: quran.lastVerse)

        guard let fileURLs = try? fileSystem.contentsOfDirectory(at: reciter.localFolder(), includingPropertiesForKeys: [.fileSizeKey]) else {
            return .zero(quran: quran)
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

        return AudioDownloadedSize(
            downloadedSizeInBytes: sizeInBytes,
            downloadedSuraCount: suras.count,
            surasCount: quran.suras.count
        )
    }

    // MARK: Internal

    let baseURL: URL
    let fileSystem: FileSystem

    // MARK: Private

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
